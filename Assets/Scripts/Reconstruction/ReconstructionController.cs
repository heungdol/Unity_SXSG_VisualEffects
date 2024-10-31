using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ReconstructionController : MonoBehaviour
{
    // [Header ("컴포넌트 세팅")]
    [SerializeField][HideInInspector] MeshRenderer m_meshRenderer;
    
    [Header ("수치 세팅")]
    [SerializeField] private float m_delay = 0.0f;
    [SerializeField] private float m_duration = 1.0f;

    void Start ()
    {
        m_meshRenderer = GetComponent<MeshRenderer> ();
    }


}
