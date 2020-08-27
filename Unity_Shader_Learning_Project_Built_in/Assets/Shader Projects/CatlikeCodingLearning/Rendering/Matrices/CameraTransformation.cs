using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraTransformation : Transformation
{
    public enum CameraTransformationType
    {
        Orthographic,
        Perspective
    }

    public float focalLen = 1.0f;
    public CameraTransformationType Type = CameraTransformationType.Orthographic;
    
    public override Matrix4x4 Matrix
    {
        get
        {
            Matrix4x4 matrix = new Matrix4x4();
            switch (Type)
            {
                case CameraTransformationType.Orthographic:
                    matrix.SetRow(0, new Vector4(1f, 0f, 0f, 0f));
                    matrix.SetRow(1, new Vector4(0f, 1f, 0f, 0f));
                    matrix.SetRow(2, new Vector4(0f, 0f, 0f, 0f));
                    matrix.SetRow(3, new Vector4(0f, 0f, 0f, 1f));
                    break;
                case CameraTransformationType.Perspective:
                    matrix.SetRow(0, new Vector4(1f*focalLen, 0f, 0f, 0f));
                    matrix.SetRow(1, new Vector4(0f, 1f*focalLen, 0f, 0f));
                    matrix.SetRow(2, new Vector4(0f, 0f, 0f, 0f));
                    matrix.SetRow(3, new Vector4(0f, 0f, 1f, 1f));
                    break;
                default:
                    matrix.SetRow(0, new Vector4(1f, 0f, 0f, 0f));
                    matrix.SetRow(1, new Vector4(0f, 1f, 0f, 0f));
                    matrix.SetRow(2, new Vector4(0f, 0f, 1f, 0f));
                    matrix.SetRow(3, new Vector4(0f, 0f, 0f, 1f));
                    break;
            }

            return matrix;
        }
    }

    public override Vector3 Apply(Vector3 point)
    {
        return Matrix.MultiplyPoint(point);
    }
}
