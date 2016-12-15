using System;
using UnityEngine;


namespace AzureTelemetry
{
    class UnityLogger
    {
        public void logData(string payload)
        {
            Debug.Log(payload);
        }
    }
}
