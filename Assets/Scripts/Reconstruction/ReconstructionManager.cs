using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Serialization;

public class ReconstructionManager : MonoBehaviour, IInputable
{
    [SerializeField][HideInInspector] private ReconstructionController m_reconstruction;
    [SerializeField][HideInInspector] private List<ReconstructionController> m_reconstructions;

    [Header ("진행 설정")]
    [SerializeField] private float m_progressDuration = 9.0f;
    [SerializeField][FormerlySerializedAs("m_controlRatio")][FormerlySerializedAs("m_controlReconstructionRatio")]  
    private AnimationCurve m_controlProgressRatioCurve = AnimationCurve.Linear (0.0f, 0.0f, 1.0f, 1.0f);   
    [SerializeField][FormerlySerializedAs("m_controlRotation_orderRatio_z")] 
    private AnimationCurve m_controlRotation_orderRatio = AnimationCurve.Linear (0.0f, 0.0f, 1.0f, 0.0f);
    [SerializeField] private AnimationCurve m_controlAddScale_orderRatio = AnimationCurve.Linear (0.0f, 1.0f, 1.0f, 1.0f);
    [SerializeField][FormerlySerializedAs("m_recontructionPosZCurve")] 
    private AnimationCurve m_adjustMaterialProgressCurve = AnimationCurve.Linear (0.0f, 0.0f, 1.0f, 200.0f);

    [Header ("컨트롤 설정")]
    [SerializeField][Range(1, 100)] private int m_recontructionCount = 10;
    [SerializeField] private Vector3 m_reconstructionArrayOffsetPosition = new Vector3 (0.0f, 0.0f, 10.0f);
    [SerializeField][Range(0.01f, 10.0f)] private float m_recontructionPieceDelay = 0.125f;
    [SerializeField][Range(0.01f, 10.0f)] private float m_recontructionPieceDuration = 2.0f;

    [Header ("Z 회전 설정")]
    [SerializeField] private AnimationCurve m_controlRotation_z = AnimationCurve.Linear (0.0f, 0.0f, 1.0f, 0.0f);
    
    [Header ("스케일 설정")]
    [SerializeField] private AnimationCurve m_controlAddScale_x = AnimationCurve.Linear (0.0f, 0.0f, 1.0f, 0.0f);
    [SerializeField] private AnimationCurve m_controlAddScale_y = AnimationCurve.Linear (0.0f, 0.0f, 1.0f, 0.0f);
    [SerializeField] private AnimationCurve m_controlAddScale_z = AnimationCurve.Linear (0.0f, 0.0f, 1.0f, 0.0f);

    [Header ("카메라 설정")]
    [SerializeField] private float m_cameraDuration;
    [SerializeField] private AnimationCurve m_cameraMoveRatioCurve = AnimationCurve.Linear (0.0f, 0.0f, 1.0f, 1.0f);
    [SerializeField] private Vector3 m_cameraStartOffset;
    [SerializeField] private Vector3 m_cameraEndOffset;
    [SerializeField] private AnimationCurve m_FOVOffsetCurve = AnimationCurve.Linear (0.0f, 0.0f, 1.0f, 0.0f);

    [SerializeField][HideInInspector] private Camera m_mainCamera;
    [SerializeField][HideInInspector] private IEnumerator m_moveCamera_CO;
    [SerializeField][HideInInspector] private float m_currentCameraRatio = 0.0f;
    [SerializeField][HideInInspector] private float m_cameraStartFOV = 60.0f;

    [Header ("머테리얼 설정")]
    [SerializeField] private Material m_recontructionMaterial = null;

    [SerializeField][HideInInspector]private IEnumerator m_currentAdjustMaterialProperty_CO = null;
    [SerializeField][HideInInspector] private bool m_braking = false;

    void Start ()
    {
        InitReconstruction ();   
        InitCamera ();
    }
    
    #region input interface

    public void InputAction_MouseLeft ()
    {
        if (m_braking == false)
        {
            m_braking = true;

            StartBrakings ();
            MoveCamera (false);
            AdjustMateiralProperty (false);
        }
    }

    public void InputAction_MouseRight ()
    {
        if (m_braking == true)
        {
            m_braking = false;

            StartReconstructings ();
            MoveCamera (true);
            AdjustMateiralProperty (true);
        }
    }

    public void InputAction_MouseMiddle ()
    {
        
    }

    #endregion

    void InitReconstruction ()
    {
        if (m_reconstruction == null)
        {
            m_reconstruction = GetComponentInChildren<ReconstructionController>();
        }

        ReconstructionController originRecontructionController = m_reconstruction;

        if (originRecontructionController == null)
        {
            throw new System.Exception ("No Recontruction Controller");
        }

        m_reconstructions = new List<ReconstructionController> ();
        m_reconstructions.AddRange (new ReconstructionController[m_recontructionCount]);

        for (int i = 0; i < m_recontructionCount; i++)
        {
            m_reconstructions[i] = Instantiate (originRecontructionController);
            
            if (m_reconstructions[i] == null)
            {
                throw new System.Exception ("No Instantiated Recontruction Controller");
            }

            m_reconstructions[i].gameObject.transform.SetParent (transform);
            m_reconstructions[i].gameObject.transform.localPosition = m_reconstructionArrayOffsetPosition * i;
        
            m_reconstructions[i].SetConstructionManager (this, 1.0f * i / m_recontructionCount);
            m_reconstructions[i].SetDurations (i * m_recontructionPieceDelay, m_recontructionPieceDuration);
            
            // m_reconstructions[i].AddRandomSeed (i);
        }

        originRecontructionController.gameObject.SetActive (false);

        if (m_recontructionMaterial)
        {
            m_recontructionMaterial.SetFloat ("_RecontructionPosZ", m_adjustMaterialProgressCurve.Evaluate (0.0f));
        }
    }

    void InitCamera ()
    {
        m_mainCamera = GetComponentInChildren<Camera>();

        if (m_mainCamera == null)
        {
            throw new System.Exception ("No Camera");
        }

        m_cameraStartFOV = m_mainCamera.fieldOfView; 
        m_mainCamera.transform.localPosition = m_cameraStartOffset;
    }

    public float WarpTimeRatio (in float _progressRatio)
    {
        return m_controlProgressRatioCurve.Evaluate (_progressRatio);
    }

    public void GetControlRotationByRatio (in float _progressRatio, in float _orderRatio, out float _rotationZ)
    {
        _rotationZ = m_controlRotation_z.Evaluate (_progressRatio) * m_controlRotation_orderRatio.Evaluate (_orderRatio);
    }

    public void GetControlScaleByRatio (in float _progressRatio, in float _orderRatio, 
    in Vector3 _original, out Vector3 _scale)
    {
        _scale.x = _original.x + m_controlAddScale_x.Evaluate (_progressRatio) * m_controlAddScale_orderRatio.Evaluate (_orderRatio);
        _scale.y = _original.y + m_controlAddScale_y.Evaluate (_progressRatio) * m_controlAddScale_orderRatio.Evaluate (_orderRatio);
        _scale.z = _original.z + m_controlAddScale_z.Evaluate (_progressRatio) * m_controlAddScale_orderRatio.Evaluate (_orderRatio);
    }


    void StartBrakings ()
    {
        foreach (var con in m_reconstructions)
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
        foreach (var con in m_reconstructions)
        {
            if (con == null)
            {
                continue;
            }
            
            con.StartReconstructing ();
        }
    }

    void MoveCamera (in bool _inverse = false)
    {
        if (m_moveCamera_CO != null)
        {
            StopCoroutine (m_moveCamera_CO);
        }

        m_moveCamera_CO = MoveCamera_CO (_inverse);
        StartCoroutine (m_moveCamera_CO);
    }

    private IEnumerator MoveCamera_CO (bool _inverse = false)
    {
        if (m_mainCamera == null)
        {
            yield break;
        }

        Vector3 startPoint = m_cameraStartOffset;
        Vector3 endPoint = m_reconstructionArrayOffsetPosition * m_recontructionCount + m_cameraEndOffset;

        if (_inverse == false)
        {
            startPoint = m_mainCamera.transform.localPosition;

            while (m_currentCameraRatio < 1.0f
            && m_cameraDuration > Mathf.Epsilon)
            {
                m_mainCamera.transform.localPosition = Vector3.Lerp 
                (startPoint
                , endPoint
                , m_cameraMoveRatioCurve.Evaluate (m_currentCameraRatio));

                m_mainCamera.fieldOfView = m_cameraStartFOV + m_FOVOffsetCurve.Evaluate(m_currentCameraRatio);
            
                m_currentCameraRatio += Time.deltaTime / m_cameraDuration;
                yield return null;
            }

            m_currentCameraRatio = 1.0f;
            
            m_mainCamera.fieldOfView = m_cameraStartFOV + m_FOVOffsetCurve.Evaluate(m_currentCameraRatio);
            m_mainCamera.transform.localPosition = endPoint;
        }
        else
        {
            endPoint = m_mainCamera.transform.localPosition;

            while (m_currentCameraRatio > 0.0f
            && m_cameraDuration > Mathf.Epsilon)
            {
                m_mainCamera.transform.localPosition = Vector3.Lerp 
                (startPoint
                , endPoint
                , m_cameraMoveRatioCurve.Evaluate (m_currentCameraRatio));
            
                m_mainCamera.fieldOfView = m_cameraStartFOV + m_FOVOffsetCurve.Evaluate(m_currentCameraRatio);

                m_currentCameraRatio -= Time.deltaTime / m_cameraDuration;
                yield return null;
            }

            m_currentCameraRatio = 0.0f;
            
            m_mainCamera.fieldOfView = m_cameraStartFOV + m_FOVOffsetCurve.Evaluate(m_currentCameraRatio);
            m_mainCamera.transform.localPosition = startPoint;
        }
    }

    void AdjustMateiralProperty (in bool _inverse = false)
    {
        if (m_currentAdjustMaterialProperty_CO != null)
        {
            StopCoroutine (m_currentAdjustMaterialProperty_CO);
        }

        m_currentAdjustMaterialProperty_CO = AdjustMaterialProperty_CO (_inverse);
        StartCoroutine (m_currentAdjustMaterialProperty_CO);
    }

    private IEnumerator AdjustMaterialProperty_CO (bool _inverse = false)
    {
        float t = 0;
        if (_inverse == false)
        {
            while (m_recontructionMaterial != null 
            && t < 1.0f)
            {
                t += Time.deltaTime / m_progressDuration;

                m_recontructionMaterial.SetFloat ("_RecontructionPosZ", m_adjustMaterialProgressCurve.Evaluate (t));

                yield return null;
            }

            t = 1.0f;

            if (m_recontructionMaterial)
            {
                m_recontructionMaterial.SetFloat ("_RecontructionPosZ", m_adjustMaterialProgressCurve.Evaluate (t));
            }
        }
        else
        {
            t = 1.0f;
            while (m_recontructionMaterial != null 
            && t > 0.0f)
            {
                t -= Time.deltaTime / m_progressDuration;

                m_recontructionMaterial.SetFloat ("_RecontructionPosZ", m_adjustMaterialProgressCurve.Evaluate (t));

                yield return null;
            }

            t = 0.0f;

            if (m_recontructionMaterial)
            {
                m_recontructionMaterial.SetFloat ("_RecontructionPosZ", m_adjustMaterialProgressCurve.Evaluate (t));
            }
        }
    }
}
