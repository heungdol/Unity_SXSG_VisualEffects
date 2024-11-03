using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Serialization;

public class ReconstructionManager : MonoBehaviour, IInputable
{
    [SerializeField][HideInInspector] private ReconstructionController m_reconstruction;
    [SerializeField][HideInInspector] private List<ReconstructionController> m_reconstructions;

    [Header ("컨트롤 설정")]
    [SerializeField][Range(1, 100)] private int m_recontructionCount = 10;
    [SerializeField] private Vector3 m_reconstructionArrayOffsetPosition = new Vector3 (0.0f, 0.0f, 10.0f);
    [SerializeField][Range(0.01f, 10.0f)] private float m_recontructionPieceDelay = 0.125f;
    [SerializeField][Range(0.01f, 10.0f)] private float m_recontructionPieceDuration = 2.0f;

    [Header ("Z 회전 설정")]
    [SerializeField][FormerlySerializedAs("m_controlRatio")][FormerlySerializedAs("m_controlReconstructionRatio")]  
    private AnimationCurve m_controlProgressRatioCurve = AnimationCurve.Linear (0.0f, 0.0f, 1.0f, 1.0f);   
    [SerializeField] private AnimationCurve m_controlRotation_z = AnimationCurve.Linear (0.0f, 0.0f, 1.0f, 0.0f);
    [SerializeField][FormerlySerializedAs("m_controlRotation_orderRatio_z")] 
    private AnimationCurve m_controlRotation_orderRatio = AnimationCurve.Linear (0.0f, 0.0f, 1.0f, 0.0f);
    
    [Header ("스케일 설정")]
    [SerializeField] private AnimationCurve m_controlAddScale_x = AnimationCurve.Linear (0.0f, 0.0f, 1.0f, 0.0f);
    [SerializeField] private AnimationCurve m_controlAddScale_y = AnimationCurve.Linear (0.0f, 0.0f, 1.0f, 0.0f);
    [SerializeField] private AnimationCurve m_controlAddScale_z = AnimationCurve.Linear (0.0f, 0.0f, 1.0f, 0.0f);
    [SerializeField] private AnimationCurve m_controlAddScale_orderRatio = AnimationCurve.Linear (0.0f, 1.0f, 1.0f, 1.0f);

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


    void Start ()
    {
        InitReconstruction ();   
        InitCamera ();
    }
    

    public void InputAction_MouseLeft ()
    {
        StartBrakings ();
        MoveCamera (false);
    }

    public void InputAction_MouseRight ()
    {
        StartReconstructings ();
        MoveCamera (true);
    }

    public void InputAction_MouseMiddle ()
    {
        
    }

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
            m_reconstructions[i].AddRandomSeed (i);
            m_reconstructions[i].SetDurations (i * m_recontructionPieceDelay, m_recontructionPieceDuration);
        }

        originRecontructionController.gameObject.SetActive (false);
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
}
