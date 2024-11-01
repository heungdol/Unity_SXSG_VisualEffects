using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ReconstructionManager : MonoBehaviour
{
    [Header ("컨트롤 설정")]
    [SerializeField] private ReconstructionController[] m_reconstructoinControllers;

    [Header ("애니메이션 커브")]
    [SerializeField] private AnimationCurve m_controlRotation_z = AnimationCurve.Linear (0.0f, 0.0f, 1.0f, 0.0f);
    [SerializeField] private AnimationCurve m_controlRotation_orderRatio_z = AnimationCurve.Linear (0.0f, 0.0f, 1.0f, 1.0f);
    
    [Space (10)]
    [SerializeField] private AnimationCurve m_controlScale_x = AnimationCurve.Linear (0.0f, 1.0f, 1.0f, 1.0f);
    [SerializeField] private AnimationCurve m_controlScale_y = AnimationCurve.Linear (0.0f, 1.0f, 1.0f, 1.0f);
    [SerializeField] private AnimationCurve m_controlScale_z = AnimationCurve.Linear (0.0f, 1.0f, 1.0f, 1.0f);

    public void GetControlRotationByRatio (in float _progressRatio, in float _orderRatio, out float _rotationZ)
    {
        _rotationZ = m_controlRotation_z.Evaluate (_progressRatio) * m_controlRotation_orderRatio_z.Evaluate (_orderRatio);
    }

    public void GetControlScaleByRatio (in float _ratio, in Vector3 _original, out Vector3 _scale)
    {
        _scale.x = _original.x * m_controlScale_x.Evaluate (_ratio);
        _scale.y = _original.y * m_controlScale_y.Evaluate (_ratio);
        _scale.z = _original.z * m_controlScale_z.Evaluate (_ratio);
    }

    void Start ()
    {
        for (int i = 0; i < m_reconstructoinControllers.Length; i++)
        {
            if (m_reconstructoinControllers[i] == null)
            {
                continue;
            }

            m_reconstructoinControllers[i].AddRandomSeed (i);
            m_reconstructoinControllers[i].SetConstructionManager (this, 1.0f * i / m_reconstructoinControllers.Length);
        }
    }

    void Update ()
    {
        if (Input.GetKeyDown (KeyCode.A))
        {
            StartBrakings ();
        }

        if (Input.GetKeyDown (KeyCode.S))
        {
            StartReconstructings ();
        }
    }

    void StartBrakings ()
    {
        foreach (var con in m_reconstructoinControllers)
        {
            if (con == null)
            {
                continue;
            }

            con.StartBraking ();
        }
    }

    void StartReconstructings ()
    {
        foreach (var con in m_reconstructoinControllers)
        {
            if (con == null)
            {
                continue;
            }
            
            con.StartReconstructing ();
        }
    }
}
