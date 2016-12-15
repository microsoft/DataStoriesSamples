using System;
using System.Globalization;
using System.Threading.Tasks;
using Windows.Web.Http;
using Windows.Security.Cryptography;
using Windows.Security.Cryptography.Core;
using System.Net;

namespace AzureTelemetry
{
    public class AzureLogger
    {
        private string sasToken;
        private HttpClient httpClient;
        private string url;

        /// applying the minimal backoff from azure guidance
        /// https://azure.microsoft.com/en-us/documentation/articles/best-practices-retry-service-specific/#service-bus-retry-guidelines
        private const int FailureRetryInterval = 1000;


        /// <summary>
        /// Logger to Azure Eventhub
        /// </summary>
        /// <param name="DeviceName">A device indentifier used for logging</param>  /// hololens
        /// <param name="ServiceNamespace">The servicebus namespace</param>  //hololens
        /// <param name="HubName">The eventhub name</param>  // hololens2
        /// <param name="AuthorizationRulekey">The KeyName of the authorization Key</param>  // RootManageSharedAccessKey
        /// <param name="AuthorizationRuleValue">The name of the Authorization Value</param>  // cjc89j93gnowDHNkbSXlY5k/JhOwKW7yD3DBma5OaME=
        public AzureLogger(string DeviceName, string ServiceNamespace,string HubName, string AuthorizationRulekey, string AuthorizationRuleValue)
        {
            httpClient = new HttpClient();
            string ServiceBusURI = string.Format("https://{0}.servicebus.windows.net", ServiceNamespace);
            url = string.Format("{0}/{1}/publishers/{2}/messages", ServiceBusURI, HubName, DeviceName);
            sasToken = createToken(ServiceBusURI, AuthorizationRulekey, AuthorizationRuleValue);
            httpClient.DefaultRequestHeaders.TryAppendWithoutValidation("Authorization", sasToken);
        }

        /// <summary>
        /// Create the SAS token
        /// </summary>
        /// <param name="resourceUri">Service BUS URI</param>
        /// <param name="keyName">THe authorization rule key name</param>
        /// <param name="key">Authorization rule key</param>
        /// <returns>The SAS token</returns>
        private string createToken(string resourceUri, string keyName, string key)
        {
            TimeSpan sinceEpoch = DateTime.UtcNow - new DateTime(1970, 1, 1);
            var day = 60 * 60 * 24;

            // Signing for 24 hours shoul dbe enough
            var expiry = Convert.ToString((int)sinceEpoch.TotalSeconds + day);
            string stringToSign = WebUtility.UrlEncode(resourceUri) + "\n" + expiry;

            var signature = GetHmacSha256(key, stringToSign);
            var sasToken = String.Format(CultureInfo.InvariantCulture, "SharedAccessSignature sr={0}&sig={1}&se={2}&skn={3}", WebUtility.UrlEncode(resourceUri), WebUtility.UrlEncode(signature), expiry, keyName);
            return sasToken;
        }

        /// <summary>
        /// Getting the SHA256 encoded string
        /// </summary>
        /// <param name="key">Signing Key</param>
        /// <param name="value">Value to sign</param>
        /// <returns>The SHA256 encoded string </returns>
        private string GetHmacSha256(string key, string value)
        {

            var keyStrm = CryptographicBuffer.ConvertStringToBinary(key, BinaryStringEncoding.Utf8);
            var valueStrm = CryptographicBuffer.ConvertStringToBinary(value, BinaryStringEncoding.Utf8);
            var objMacProv = MacAlgorithmProvider.OpenAlgorithm(MacAlgorithmNames.HmacSha256);
            var hash = objMacProv.CreateHash(keyStrm);
            hash.Append(valueStrm);
            return CryptographicBuffer.EncodeToBase64String(hash.GetValueAndReset());

        }

        /// <summary>
        /// Sending the payload to Azure Hub
        /// Guidelines from: https://azure.microsoft.com/en-us/documentation/articles/best-practices-retry-general/
        /// </summary>
        /// <param name="payload">The payload to send</param>
        /// <param name="retries">The number of retries. Set to 1 to just handle transient faults; per azure guidelines.</param>
        /// <returns>The HttpStatusCode</returns>
        public async Task<Windows.Web.Http.HttpStatusCode> sendData(string payload, int retries = 1)
        {
            if (retries < 0)
                return Windows.Web.Http.HttpStatusCode.GatewayTimeout;


            HttpStringContent content = new HttpStringContent(payload, Windows.Storage.Streams.UnicodeEncoding.Utf8, "application/json");
            HttpResponseMessage response = new HttpResponseMessage
            {
                StatusCode = Windows.Web.Http.HttpStatusCode.BadRequest
            };

            try
            {
                response = await httpClient.PostAsync(new Uri(url), content);
                return response.StatusCode;
            }
            catch (WebException e)
            {
                await Task.Delay(TimeSpan.FromMilliseconds(FailureRetryInterval));
                return await this.sendData(payload, retries--);
            } 
        }

    }
}
