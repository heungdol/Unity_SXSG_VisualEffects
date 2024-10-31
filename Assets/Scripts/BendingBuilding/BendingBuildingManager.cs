using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BendingBuildingManager : MonoBehaviour
{
    [Header ("벤딩 빌딩 컨트롤러 설정")]
    [SerializeField] BendingBuildingController[] m_bendingBuildingControllers;

    void Start ()
    {

    }

    void Update ()
    {
        if (Input.GetKeyDown (KeyCode.A))
        {
            StartBendingBuildings ();
        }

        if (Input.GetKeyDown (KeyCode.S))
        {
            StartBendingBuildings (isInverse : true);
        }
    }

    public void StartBendingBuildings (bool isInverse = false)
    {
        if (m_bendingBuildingControllers == null)
        {
            return;
        }

        if (m_bendingBuildingControllers.Length <= 0)
        {
            return;
        }

        foreach (var bendingBuilding in m_bendingBuildingControllers)
        {
            bendingBuilding.StartBending (isInverse);
        }
    }
}
