using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UIElements;

public class ReconstructionController : MonoBehaviour
{
    // [Header ("컴포넌트 세팅")]
    [SerializeField][HideInInspector] MeshRenderer m_meshRenderer;
    
    // [Header ("수치 세팅")]
    [SerializeField] [HideInInspector]private float m_delay = 0.0f;
    [SerializeField] [HideInInspector] private float m_duration = 1.0f;

    [SerializeField] [HideInInspector] private Quaternion m_startRotation = Quaternion.identity;
    [SerializeField] [HideInInspector] private Vector3 m_startScale = Vector3.one;

    [SerializeField] [HideInInspector] private float m_currentRatio = 0.0f;
    [SerializeField] [HideInInspector] private float m_orderRatio = 0.0f;

    [SerializeField] [HideInInspector] private IEnumerator m_current_CO = null;
    [SerializeField] [HideInInspector] private ReconstructionManager m_reconstructionManager = null;

    void Start ()
    {
        if (m_meshRenderer == null)
        {
            m_meshRenderer = GetComponent<MeshRenderer> ();
        }

        // m_reconstructionManager = GetComponentInParent<ReconstructionManager>();

        m_startRotation = gameObject.transform.localRotation;
        m_startScale = gameObject.transform.localScale;

        m_meshRenderer.material.SetFloat ("_RecontructionRate", 0.0f);
    }

    public void SetConstructionManager (in ReconstructionManager _manager, in float _orderRatio)
    {
        m_reconstructionManager = _manager;
        m_orderRatio = _orderRatio;
    }

    public void SetDurations (in float _delay, in float _duration)
    {
        m_delay = _delay;
        m_duration = _duration;
    }

    public void AddRandomSeed (in int _increase)
    {
        if (m_meshRenderer == null)
        {
            m_meshRenderer = GetComponent<MeshRenderer> ();
        }

        m_meshRenderer.material.SetInt ("_RandomSeed", m_meshRenderer.material.GetInt("_RandomSeed") + _increase);
    }

    private float WrapingTimeRatio (in float _currentT)
    {
        return m_reconstructionManager.WarpTimeRatio(_currentT);// Mathf.Sin((_currentT - 0.5f) * Mathf.PI) * 0.5f + 0.5f;
    }

    public void StartBraking ()
    {
        if (m_current_CO != null)
        {
            StopCoroutine (m_current_CO);
        }

        m_current_CO = Braking_CO ();
        StartCoroutine (m_current_CO);
    }

    IEnumerator Braking_CO ()
    {
        yield return new WaitForSeconds (m_delay);

        float controlRotation = 0.0f;
        Vector3 controlScale = Vector3.one;

        while (m_currentRatio < 1.0f)
        {
            m_currentRatio += Time.deltaTime / m_duration;
            m_meshRenderer.material.SetFloat ("_RecontructionRate", WrapingTimeRatio(m_currentRatio));

            m_reconstructionManager.GetControlRotationByRatio(m_currentRatio, m_orderRatio, out controlRotation);
            m_reconstructionManager.GetControlScaleByRatio(m_currentRatio, m_orderRatio, m_startScale, out controlScale);

            gameObject.transform.localRotation = m_startRotation * Quaternion.Euler(0.0f, 0.0f, controlRotation);
            gameObject.transform.localScale = controlScale;

            yield return null;
        }

        m_currentRatio = 1.0f;
        m_meshRenderer.material.SetFloat ("_RecontructionRate", WrapingTimeRatio(m_currentRatio));

        m_reconstructionManager.GetControlRotationByRatio(m_currentRatio, m_orderRatio, out controlRotation);
        m_reconstructionManager.GetControlScaleByRatio(m_currentRatio, m_orderRatio, m_startScale, out controlScale);

        gameObject.transform.localRotation = m_startRotation * Quaternion.Euler(0.0f, 0.0f, controlRotation);
        gameObject.transform.localScale = controlScale;
        
    }

    public void StartReconstructing ()
    {
        if (m_current_CO != null)
        {
            StopCoroutine (m_current_CO);
        }

        m_current_CO = Reconstructing_CO ();
        StartCoroutine (m_current_CO);
    }

    IEnumerator Reconstructing_CO ()
    {
        yield return new WaitForSeconds (m_delay);
        
        float controlRotation = 0.0f;
        Vector3 controlScale = Vector3.one;
        
        while (m_currentRatio > 0.0f)
        {
            m_currentRatio -= Time.deltaTime / m_duration;
            m_meshRenderer.material.SetFloat ("_RecontructionRate", WrapingTimeRatio(m_currentRatio));

            m_reconstructionManager.GetControlRotationByRatio(m_currentRatio, m_orderRatio, out controlRotation);
            m_reconstructionManager.GetControlScaleByRatio(m_currentRatio, m_orderRatio, m_startScale, out controlScale);

            gameObject.transform.localRotation = m_startRotation * Quaternion.Euler(0.0f, 0.0f, controlRotation);
            gameObject.transform.localScale = controlScale;
            
            yield return null;
        }

        m_currentRatio = 0.0f;
        m_meshRenderer.material.SetFloat ("_RecontructionRate", WrapingTimeRatio(m_currentRatio));

        m_reconstructionManager.GetControlRotationByRatio(m_currentRatio, m_orderRatio, out controlRotation);
        m_reconstructionManager.GetControlScaleByRatio(m_currentRatio, m_orderRatio, m_startScale, out controlScale);

        gameObject.transform.localRotation = m_startRotation * Quaternion.Euler(0.0f, 0.0f, controlRotation);
        gameObject.transform.localScale = controlScale;
    }
}
