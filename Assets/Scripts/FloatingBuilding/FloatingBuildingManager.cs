using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FloatingBuildingManager : MonoBehaviour
{
    [Header ("컴포넌트 세팅")]
    [SerializeField] private FloatingBuildingController m_controller_bottom;
    [SerializeField] private FloatingBuildingController m_controller_middle;
    [SerializeField] private FloatingBuildingController m_controller_top;

    [Header ("수치 설정")]
    [SerializeField] private int m_middleCounts = 10;
    [SerializeField] private Vector3 m_localRotaionStartRatio = new Vector3 (0.0f, 0.0f, 0.0f);
    [SerializeField] private Vector3 m_localRotaionDuration = new Vector3 (0.0f, 0.0f, 0.0f);
    [SerializeField] private Vector3 m_localRotaionMax = new Vector3 (0.0f, 0.0f, 0.0f);

    [SerializeField] private List<GameObject> m_pivots = new List<GameObject>();
    [SerializeField] private Vector3 m_localRotationRatio = new Vector3 (0.0f, 0.0f, 0.0f);

    void Start ()
    {
        InitFloatingBuiliding ();

        m_localRotationRatio = m_localRotaionStartRatio;
    }

    void Update ()
    {
        if (m_localRotaionDuration.x > Mathf.Epsilon)
        {
            m_localRotationRatio.x += Time.deltaTime / m_localRotaionDuration.x;
        }

        if (m_localRotaionDuration.y > Mathf.Epsilon)
        {
            m_localRotationRatio.y += Time.deltaTime / m_localRotaionDuration.y;
        }

        if (m_localRotaionDuration.z > Mathf.Epsilon)
        {
            m_localRotationRatio.z += Time.deltaTime / m_localRotaionDuration.z;
        }

        foreach (var pivot in m_pivots)
        {   
            pivot.gameObject.transform.localRotation = Quaternion.Euler 
            (Mathf.Sin (m_localRotationRatio.x * Mathf.PI) * m_localRotaionMax.x
            , Mathf.Sin (m_localRotationRatio.y * Mathf.PI) * m_localRotaionMax.y
            , Mathf.Sin (m_localRotationRatio.z * Mathf.PI) * m_localRotaionMax.z);
        }
    }

    void InitFloatingBuiliding ()
    {
        FloatingBuildingController tempParent = m_controller_bottom;
        FloatingBuildingController tempMid = m_controller_middle;

        for (int i = 0; i < m_middleCounts; i++)
        {
            tempMid.gameObject.transform.SetParent (tempParent.gameObject.transform);
            tempMid.gameObject.transform.localPosition = tempParent.EndPointObject.gameObject.transform.localPosition;
            
            tempParent = tempMid;
            m_pivots.Add (tempParent.gameObject);

            if (i != m_middleCounts - 1)
            {
                tempMid = Instantiate (tempMid);
            }
        }

        m_controller_top.gameObject.transform.SetParent (tempParent.gameObject.transform);
        m_controller_top.gameObject.transform.localPosition = tempParent.EndPointObject.gameObject.transform.localPosition;

        m_pivots.Add (m_controller_top.gameObject);
    }
}
