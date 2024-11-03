using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using UnityEngine;

public class InputManager : MonoBehaviour
{
    [Header ("인풋 컴포넌트")]
    [SerializeField] private List<IInputable> m_inputableComponents = new List<IInputable>();

    void Start()
    {
        m_inputableComponents.AddRange(GameObject.FindObjectsOfType<MonoBehaviour>().OfType<IInputable>());
    }

    void Update ()
    {
        if (Input.GetKeyDown (KeyCode.Mouse0))
        {
            foreach (var iinput in m_inputableComponents)
            {
                if (iinput == null)
                {
                    continue;
                }

                iinput.InputAction_MouseLeft ();
            } 
        }

        if (Input.GetKeyDown (KeyCode.Mouse1))
        {
            foreach (var iinput in m_inputableComponents)
            {
                if (iinput == null)
                {
                    continue;
                }

                iinput.InputAction_MouseRight ();
            } 
        }
    }
}
