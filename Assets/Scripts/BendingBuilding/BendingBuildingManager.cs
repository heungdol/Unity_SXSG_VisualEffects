using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BendingBuildingManager : MonoBehaviour, IInputable
{
    [SerializeField][HideInInspector] BendingBuildingController[] m_bendingBuildingControllers;

    [Header ("진행 설정")]
    [SerializeField] private float m_progressDuration = 9.0f;
    [SerializeField] private AnimationCurve m_adjustMaterialProgressCurve = AnimationCurve.Linear (0.0f, 0.0f, 1.0f, 200.0f);


    [Header ("컨트롤러 설정")]
    [SerializeField] private AnimationCurve m_controlProgressRatioCurve = AnimationCurve.Linear (0.0f, 0.0f, 1.0f, 1.0f);   
    [SerializeField] public AnimationCurve ControlProgressRatioCurve => m_controlProgressRatioCurve;

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
    [SerializeField][HideInInspector] private Vector3 m_cameraLocalPosition = Vector3.zero;

    [Header ("머테리얼 설정")]
    [SerializeField] private Material m_bendingBuildingMaterial = null;

    [SerializeField] private IEnumerator m_currentAdjustMaterialProperty_CO = null;
    [SerializeField][HideInInspector] private bool m_isBending = false;

    void Start ()
    {
        InitControllers ();
        InitCamera ();
    }

    void Update ()
    {

    }

    #region input interface

    public void InputAction_MouseLeft ()
    {
        if (m_isBending == false)
        {
            m_isBending = true;
            
            // StartBendingBuildings ();
            MoveCamera ();
            AdjustMateiralProperty (false);
        }
    }

    public void InputAction_MouseRight ()
    {
        if (m_isBending == true)
        {
            m_isBending = false;

            // StartBendingBuildings (isInverse : true);
            MoveCamera (_inverse:true);
            AdjustMateiralProperty (true);
        }
    }

    public void InputAction_MouseMiddle ()
    {
        
    }

    #endregion

    void InitControllers ()
    {
        m_bendingBuildingControllers = GetComponentsInChildren<BendingBuildingController>();

        foreach (var con in m_bendingBuildingControllers)
        {
            if (con == null)
            {
                continue;
            }

            con.SetBendingBuildingManager (this);
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
        m_cameraLocalPosition = m_mainCamera.transform.localPosition;

        m_mainCamera.transform.localPosition = m_cameraStartOffset + m_cameraLocalPosition;
    }

    // public void StartBendingBuildings (bool isInverse = false)
    // {
    //     if (m_bendingBuildingControllers == null)
    //     {
    //         return;
    //     }

    //     if (m_bendingBuildingControllers.Length <= 0)
    //     {
    //         return;
    //     }

    //     foreach (var bendingBuilding in m_bendingBuildingControllers)
    //     {
    //         bendingBuilding.StartBending (isInverse);
    //     }
    // }

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

        Vector3 startPoint = m_cameraStartOffset + m_cameraLocalPosition;
        Vector3 endPoint = m_cameraEndOffset + m_cameraLocalPosition;

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
            while (m_bendingBuildingMaterial != null 
            && t < 1.0f)
            {
                t += Time.deltaTime / m_progressDuration;

                m_bendingBuildingMaterial.SetFloat ("_BendingPosZ", m_adjustMaterialProgressCurve.Evaluate (t));

                yield return null;
            }

            t = 1.0f;
            if (m_bendingBuildingMaterial)
            {
                m_bendingBuildingMaterial.SetFloat ("_BendingPosZ", m_adjustMaterialProgressCurve.Evaluate (t));
            }
        }
        else
        {
            t = 1.0f;
            while (m_bendingBuildingMaterial != null 
            && t > 0.0f)
            {
                t -= Time.deltaTime / m_progressDuration;

                m_bendingBuildingMaterial.SetFloat ("_BendingPosZ", m_adjustMaterialProgressCurve.Evaluate (t));

                yield return null;
            }

            t = 0.0f;
            if (m_bendingBuildingMaterial)
            {
                m_bendingBuildingMaterial.SetFloat ("_BendingPosZ", m_adjustMaterialProgressCurve.Evaluate (t));
            }
        }
    }
}
