using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Serialization;

public class CameraManager : MonoBehaviour, IInputable
{
    // [SerializeField][HideInInspector] private Vector3 m_startPosition;
    [SerializeField][HideInInspector] private Quaternion m_startRotation;
    [SerializeField][HideInInspector] private float m_startFOV;

    [SerializeField][HideInInspector] private Camera m_mainCamera;

    [Space (10)]
    [SerializeField] private float m_duration;

    [Space (10)]
    [SerializeField] private AnimationCurve m_moveRatioCurve = AnimationCurve.Linear (0.0f, 0.0f, 1.0f, 1.0f);
    [SerializeField] private GameObject m_startMovePointObject;
    [SerializeField] private GameObject m_endMovePointObject;

    [Space (10)]
    [SerializeField] private AnimationCurve m_FOVOffsetCurve = AnimationCurve.Linear (0.0f, 0.0f, 1.0f, 0.0f);

    // [Space (10)]
    // [SerializeField]

    [SerializeField] IEnumerator m_moveCamera_CO;
    [SerializeField] float m_currentRatio = 0.0f;

    void Start ()
    {
        m_mainCamera = GetComponentInChildren <Camera>();

        m_startRotation = m_mainCamera.gameObject.transform.localRotation;

        m_startFOV = m_mainCamera.fieldOfView;
    }

    public void InputAction_MouseLeft ()
    {
        MoveCamera (false);
    }

    public void InputAction_MouseRight ()
    {
        MoveCamera (true);
    }

    public void InputAction_MouseMiddle ()
    {
        
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

        if (_inverse == false)
        {
            while (m_currentRatio < 1.0f
            && m_duration > Mathf.Epsilon)
            {
                m_mainCamera.transform.localPosition = Vector3.Lerp 
                (m_startMovePointObject.gameObject.transform.localPosition
                , m_endMovePointObject.gameObject.transform.localPosition
                , m_moveRatioCurve.Evaluate (m_currentRatio));

                m_mainCamera.fieldOfView = m_startFOV + m_FOVOffsetCurve.Evaluate(m_currentRatio);
            
                m_currentRatio += Time.deltaTime / m_duration;
                yield return null;
            }

            m_currentRatio = 1.0f;
            
            m_mainCamera.fieldOfView = m_startFOV + m_FOVOffsetCurve.Evaluate(m_currentRatio);
            m_mainCamera.transform.localPosition = m_endMovePointObject.transform.localPosition;
        }
        else
        {
            while (m_currentRatio > 0.0f
            && m_duration > Mathf.Epsilon)
            {
                m_mainCamera.transform.localPosition = Vector3.Lerp 
                (m_startMovePointObject.gameObject.transform.localPosition
                , m_endMovePointObject.gameObject.transform.localPosition
                , m_moveRatioCurve.Evaluate (m_currentRatio));
            
                m_mainCamera.fieldOfView = m_startFOV + m_FOVOffsetCurve.Evaluate(m_currentRatio);

                m_currentRatio -= Time.deltaTime / m_duration;
                yield return null;
            }

            m_currentRatio = 0.0f;
            
            m_mainCamera.fieldOfView = m_startFOV + m_FOVOffsetCurve.Evaluate(m_currentRatio);
            m_mainCamera.transform.localPosition = m_startMovePointObject.transform.localPosition;
        }

    }
}
