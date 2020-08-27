using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Scaling : Transformation
{
    public Vector3 scaleVector = Vector3.one;

    public override Matrix4x4 Matrix
    {
        get
        {
            Matrix4x4 matrix = new Matrix4x4();
            matrix.SetRow(0, new Vector4(scaleVector.x, 0f, 0f, 0f));
            matrix.SetRow(1, new Vector4(0f, scaleVector.y, 0f, 0f));
            matrix.SetRow(2, new Vector4(0f, 0f, scaleVector.z, 0f));
            matrix.SetRow(3, new Vector4(0f, 0f, 0f, 1f));
            return matrix;
        }
    }

    public override Vector3 Apply(Vector3 point)
    {
        return Matrix.MultiplyPoint(point);
    }
}
