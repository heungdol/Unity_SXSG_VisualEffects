using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

public class BendingBuildingController : MonoBehaviour
{
    // [Header ("컴포넌트 세팅")]
    // [SerializeField][HideInInspector] MeshRenderer m_bendingBuildingMeshRenderer;
    
    // [Header ("수치 세팅")]
    // [SerializeField] private float m_delay = 0.0f;
    // [SerializeField] private float m_duration = 1.0f;

    // [SerializeField] private float m_startPivotX = 100.0f;
    // [SerializeField] private float m_endPivotX = 0.0f;

    // private IEnumerator m_bending_CO;

    private BendingBuildingManager m_bendingBuildingManager;

    public void SetBendingBuildingManager (BendingBuildingManager _bendingBuildingManager)
    {
        m_bendingBuildingManager = _bendingBuildingManager;
    }

    void Start ()
    {
        // m_bendingBuildingMeshRenderer = GetComponent<MeshRenderer>();

        // ResetBending ();
    }

    // public void StartBending (bool inverse = false)
    // {
    //     if (m_bending_CO != null)
    //     {
    //         StopCoroutine (m_bending_CO);
    //     }

    //     m_bending_CO = Bending_CO(inverse);
    //     StartCoroutine (m_bending_CO);
    // }

    // private IEnumerator Bending_CO (bool inverse = false)
    // {
    //     if (m_bendingBuildingMeshRenderer == null)
    //     {
    //         yield break;
    //     }

    //     yield return new WaitForSeconds (m_delay);

    //     float t = 0.0f;
    //     float trueT = t;

    //     float trueStart = m_bendingBuildingMeshRenderer.material.GetFloat ("_PivotX");
    //     float trueEnd = m_endPivotX;

    //     float trueRatioStart = m_bendingBuildingMeshRenderer.material.GetFloat ("_BendingRatio");
    //     float trueRatioEnd = 1.0f;
        
    //     if (inverse)
    //     {
    //         trueEnd = m_startPivotX;
    //         trueRatioEnd = 0.0f;
    //     }

    //     while (t < 1.0f 
    //     && m_duration > Mathf.Epsilon)
    //     {
    //         if (m_bendingBuildingManager != null)
    //         {
    //             trueT = m_bendingBuildingManager.ControlProgressRatioCurve.Evaluate (t);
    //         }
    //         else
    //         {
    //             trueT = Mathf.Sin((t - 0.5f) * Mathf.PI) * 0.5f + 0.5f;
    //             trueT = Mathf.Pow (trueT, 0.25f);
    //         }

    //         m_bendingBuildingMeshRenderer.material.SetFloat ("_BendingRatio", Mathf.Lerp (trueRatioStart, trueRatioEnd, trueT));
    //         m_bendingBuildingMeshRenderer.material.SetFloat ("_PivotX", Mathf.Lerp (trueStart, trueEnd, trueT));
            
    //         t += Time.deltaTime / m_duration;
    //         yield return null;
    //     }

    //     m_bendingBuildingMeshRenderer.material.SetFloat ("_BendingRatio", trueRatioEnd);
    //     m_bendingBuildingMeshRenderer.material.SetFloat ("_PivotX", trueEnd);
    // }

    // void ResetBending ()
    // {
    //     if (m_bendingBuildingMeshRenderer != null)
    //     {
    //         m_bendingBuildingMeshRenderer.material.SetFloat ("_BendingRatio", 0.0f);
    //         m_bendingBuildingMeshRenderer.material.SetFloat ("_PivotX", m_startPivotX);
    //     }
    // }
}
