using System;
using System.Collections.Generic;
using System.Globalization;
using System.Net;
using System.Threading;
using Newtonsoft.Json;
#if WINDOWS_UWP
using System.Threading.Tasks;
using HttpStatusCode = Windows.Web.Http.HttpStatusCode;
#endif
using UnityEngine;

namespace AzureTelemetry
{
    public class LoggerHub
    {
        private const int ProcessEventsMillis = 5000;
        private readonly List<string> eventsDictionary = new List<string>();
        private volatile bool shouldProcessEvents;

#if WINDOWS_UWP
                // lifting the values from the Azure Servicebus guidelines
        // link: https://azure.microsoft.com/en-us/documentation/articles/best-practices-retry-service-specific/#service-bus-retry-guidelines
        private int MaxRetryCount = 4;
        private int DeltaBackoff_millis = 1750;   
        private AzureLogger azureLogger;
#else
        private UnityLogger unityLogger;
#endif

        /// <summary>
        /// Logger to Azure Eventhub
        /// </summary>
        /// <param name="DeviceName">A device indentifier used for logging</param>  /// hololens
        /// <param name="ServiceNamespace">The servicebus namespace</param>  //hololens
        /// <param name="HubName">The eventhub name</param>  // hololens2
        /// <param name="AuthorizationRulekey">The KeyName of the authorization Key</param>  // RootManageSharedAccessKey
        /// <param name="AuthorizationRuleValue">The name of the Authorization Value</param>  // cjc89j93gnowDHNkbSXlY5k/JhOwKW7yD3DBma5OaME=
        public LoggerHub(string DeviceName, string ServiceNamespace, string HubName, string AuthorizationRulekey, string AuthorizationRuleValue)
        {
#if WINDOWS_UWP
            this.azureLogger = new AzureLogger(DeviceName, ServiceBusURI, ServiceNamespace, HubName, AuthorizationRulekey, AuthorizationRuleValue);
#else
            this.unityLogger = new UnityLogger();
#endif
        }

        public void StartProc()
        {
            this.shouldProcessEvents = true;
            this.ProcessOnSeparateThread(this.ProcessEvents);
        }

        public void StopProc()
        {
            this.shouldProcessEvents = false;
        }

        private void ProcessOnSeparateThread(Action action)
        {
#if WINDOWS_UWP
            Task.Run(action);
#else
            var ts = new ThreadStart(action);
            var backgroundThread = new Thread(ts);
            backgroundThread.Start();
#endif
        }

        /// <summary>
        /// Retry guidelines from Azure service bus best practices
        /// </summary>
#if WINDOWS_UWP
        private async void ProcessEvents()
#else
        private void ProcessEvents()
#endif
        {
            while (this.shouldProcessEvents)
            {
                var jsonPayload = string.Empty;
                lock (this.eventsDictionary)
                {
                    if (this.eventsDictionary.Count > 0)
                    {
                        jsonPayload = JsonConvert.SerializeObject(this.eventsDictionary);
                        this.eventsDictionary.Clear();
                    }
                }



#if WINDOWS_UWP
                this.sendDataWithRetries(jsonPayload, 0);
                await Task.Delay(TimeSpan.FromMilliseconds(ProcessEventsMillis));
#else
                this.unityLogger.logData(jsonPayload);
                Thread.Sleep(ProcessEventsMillis);
#endif
            }
        }

#if WINDOWS_UWP
        private async void sendDataWithRetries(string payload, int retries)     
        {
            if (retries > MaxRetryCount)
                return;


            var httpStatusCode = await this.azureLogger.sendData(payload);   

            if (httpStatusCode != HttpStatusCode.Created)
            {
                retries++;
                int sleepTimeMillis = 2^retries * 1000 + DeltaBackoff_millis;
                await Task.Delay(TimeSpan.FromMilliseconds(sleepTimeMillis));
                this.sendDataWithRetries(payload, retries);
            }           
        }
#endif

            /// <summary>
            /// Adding the gazed object identifier to the dictionary
            /// </summary>
            /// <param name="objectName">Name to add</param>
        public void AddGazeEvent(string objectName)
        {
            lock (this.eventsDictionary)
            {
                this.eventsDictionary.Add(objectName);
            }
        }
    }
}