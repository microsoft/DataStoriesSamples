using UnityEngine;
using UnityEngine.VR.WSA.Input;
using AzureTelemetry;

public class GazeGestureManager : MonoBehaviour
{
    public static GazeGestureManager Instance { get; private set; }

    // Represents the hologram that is currently being gazed at.
    public GameObject FocusedObject { get; private set; }

    GestureRecognizer recognizer;
    LoggerHub logger;

    // Use this for initialization
    void Start()
    {
        Instance = this;

        // Set up a GestureRecognizer to detect Select gestures.
        recognizer = new GestureRecognizer();
        recognizer.TappedEvent += (source, tapCount, ray) =>
        {
            // Send an OnSelect message to the focused object and its ancestors.
            if (FocusedObject != null)
            {
                FocusedObject.SendMessageUpwards("OnSelect");
            }
        };
        recognizer.StartCapturingGestures();

        logger = new LoggerHub(
                     "DEVICE ID - HUBPARITION ID",
                     "NAMESPACE",
                     "EVENT HUB NAME",
                     "POLICY NAME",
                     "POLICY PRIMARY KEY");
        this.logger.StartProc();
    }

    // Update is called once per frame
    void Update()
    {
        // Figure out which hologram is focused this frame.
        GameObject oldFocusObject = FocusedObject;

        // Do a raycast into the world based on the user's
        // head position and orientation.
        var headPosition = Camera.main.transform.position;
        var gazeDirection = Camera.main.transform.forward;

        RaycastHit hitInfo;
        if (Physics.Raycast(headPosition, gazeDirection, out hitInfo))
        {
            // If the raycast hit a hologram, use that as the focused object.
            FocusedObject = hitInfo.collider.gameObject;

            // Report the name of the object being hit
            if (FocusedObject != oldFocusObject
                && FocusedObject != null
                && FocusedObject.gameObject != null
                && FocusedObject.gameObject.name != null)
            {
                logger.AddGazeEvent(FocusedObject.gameObject.name);
            }
        }
        else
        {
            // If the raycast did not hit a hologram, clear the focused object.
            FocusedObject = null;
        }

        // If the focused object changed this frame,
        // start detecting fresh gestures again.
        if (FocusedObject != oldFocusObject)
        {
            recognizer.CancelGestures();
            recognizer.StartCapturingGestures();
        }
    }

    private void OnDestroy()
    {
        this.logger.StopProc();
    }
}