using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FloatingBuildingController : MonoBehaviour
{
    #region private 
    [Header ("컴포넌트 설정")]
    // [SerializeField] private GameObject m_startPoint;
    [SerializeField] private GameObject m_endPoint;

    #endregion

    #region public

    // [SerializeField] public GameObject StartPointObject => m_startPoint;
    [SerializeField] public GameObject EndPointObject => m_endPoint;

    #endregion
}
