using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class HzbInstance : MonoBehaviour
{
    public ComputeShader cullingShader;
    public Mesh grassMesh;
    public Material grassMaterial;

    public static RenderTexture HzbDepth;

    private ComputeBuffer _argBuffer;
    private ComputeBuffer _posBuffer;
    private ComputeBuffer _posVisibleBuffer;
    private uint[] _args;
    private int _cullingKernelID;
    private Bounds _bounds;

    private int resolution;     //地形尺寸

    private void Start()
    {
        #region ResCheck

        if (cullingShader == null)
        {
            return;
        }

        _cullingKernelID = cullingShader.FindKernel("CSCulling");
        #endregion
        
        #region GetGrassPos

        var terrain = FindObjectOfType<Terrain>();
        var map = terrain.terrainData.GetDetailLayer(0, 0, terrain.terrainData.detailWidth,
            terrain.terrainData.detailHeight, 0);
        resolution = terrain.terrainData.detailResolution;
        float xLen = terrain.terrainData.detailWidth / (float) resolution;
        float zLen = terrain.terrainData.detailHeight / (float) resolution;
        List<Vector3> posList = new List<Vector3>();
        int n = 0;
        for (int i = 0; i < resolution; i++)
        {
            for (int j = 0; j < resolution; j++)
            {
                if (map[i, j] != 0)
                {
                    Vector3 tempPos = new Vector3(j * xLen, 0, i * zLen);
                    tempPos.y = terrain.SampleHeight(tempPos);
                    // GameObject.Instantiate()
                    posList.Add(tempPos);
                    n++;
                }
            }
        }
        Debug.Log($"剔除前，场景里共有{n}株草");
        _posBuffer = new ComputeBuffer(n, 4 * 3);
        _posBuffer.SetData(posList);
        cullingShader.SetBuffer(_cullingKernelID, "posAllBuffer", _posBuffer);
        
        #endregion

        #region SetBuffer

        _bounds = terrain.terrainData.bounds;
        _args = new uint[] { grassMesh.GetIndexCount(0), 0, grassMesh.GetIndexStart(0), grassMesh.GetBaseVertex(0), 0 };
        _argBuffer = new ComputeBuffer(1, sizeof(uint) * _args.Length, ComputeBufferType.IndirectArguments);
        _argBuffer.SetData(_args);
        cullingShader.SetBuffer(_cullingKernelID, "argBuffer", _argBuffer);
        
        _posVisibleBuffer = new ComputeBuffer(n, 4 * 3);
        cullingShader.SetBuffer(_cullingKernelID, "posVisibleBuffer", _posVisibleBuffer);
        Culling();
        grassMaterial.SetBuffer("posVisibleBuffer", _posVisibleBuffer);
        #endregion
    }

    private void Update()
    {
        Culling();
        Graphics.DrawMeshInstancedIndirect(grassMesh, 0, grassMaterial, _bounds, _argBuffer, 0, null, ShadowCastingMode.Off, false);
        
    }

    void Culling()
    {
        _args[1] = 0;
        _argBuffer.SetData(_args);
        cullingShader.SetTexture(_cullingKernelID, "HzbDepth", HzbDepth);
        cullingShader.SetVector("cameraPos", Camera.main.transform.position);
        cullingShader.SetVector("cameraDir", Camera.main.transform.forward);
        cullingShader.SetFloat("cameraHalfFov", Camera.main.fieldOfView / 2);
        var m = GL.GetGPUProjectionMatrix( Camera.main.projectionMatrix,false) * Camera.main.worldToCameraMatrix;
        cullingShader.SetMatrix("matrix_VP", m);
        cullingShader.SetInt("resolution", resolution);
        cullingShader.Dispatch(_cullingKernelID, resolution / 16, resolution / 16, 1);
        
        // int[] data = new int[5];
        // _argBuffer.GetData(data);
    }

    private void OnDisable()
    {
        if (_argBuffer != null)
        {
            _argBuffer.Release();
        }
        _argBuffer = null;
        
        if (_posBuffer != null)
        {
            _posBuffer.Release();
        }
        _posBuffer = null;
        
        if (_posVisibleBuffer != null)
        {
            _posVisibleBuffer.Release();
        }
        _posVisibleBuffer = null;
    }
}
