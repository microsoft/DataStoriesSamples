CREATE PROCEDURE [dbo].[usp_ImagesDB_detect_places]
AS
BEGIN
DECLARE @MyTempTable TABLE
    (
        ImageID   int NOT NULL,
        Place   varchar(50),
		Prob    float NULL
    );

INSERT INTO @MyTempTable
EXECUTE sp_execute_external_script
@language=N'Python',
@script=N'
import pandas as pd
# load up the caffe2 workspace
from caffe2.python import workspace
from caffe2.python.tutorials import helpers

def map_results(results):
    import numpy as np
    import csv
    results = np.asarray(results)
    results = np.delete(results, 1)
    index = 0
    highest = 0
    arr = np.empty((0,2), dtype=object)
    arr[:,0] = int(10)
    arr[:,1:] = float(10)
    for i, r in enumerate(results):
        # imagenet index begins with 1!
        i=i+1
        arr = np.append(arr, np.array([[i,r]]), axis=0)
        if (r > highest):
            highest = r
            index = i

    # top 3 results
    #print("Raw top 3 results:", sorted(arr, key=lambda x: x[1], reverse=True)[:3])

    CATEGORY_MAPPING = "C:\demo\models\places-cnn\categories_places365.txt"
    with open(CATEGORY_MAPPING,''r'') as f:
        for line in f:
            categoryname, label = line.partition(" ")[::2]
            if (label.strip() == str(index)):
                category_result = categoryname.strip().split("/")[2]
                prob = highest
    return category_result, prob

# load the pre-trained model
# the Caffe2 models here was converted from Places365 published by http://places.csail.mit.edu/
CAFFE_MODELS = "C:\demo\models"
MODEL = ''places-cnn'', ''init_net.pb'', ''predict_net.pb''
INIT_NET = os.path.join(CAFFE_MODELS, MODEL[0], MODEL[1])
PREDICT_NET = os.path.join(CAFFE_MODELS, MODEL[0], MODEL[2])
with open(INIT_NET, ''rb'') as f:
    init_net = f.read()
with open(PREDICT_NET, ''rb'') as f:
    predict_net = f.read()

p = workspace.Predictor(init_net, predict_net)

predictions = [''''] * len(InputDataSet)
probs = [0] * len(InputDataSet)
for i in range(0, len(InputDataSet)):
    img = InputDataSet.iloc[i][''ImagePath'']

	# dimension of the images that the model was trained with
    input_dim = 227
    mean = 128

    # use the image helper to load the image and perform image pre-processing
    img = helpers.loadToNCHW(img, mean, input_dim)

    # submit the image to net and get a tensor of results
    results = p.run([img]) 

    # lookup the result from the places category list
    predictions[i], probs[i] = map_results(results)

InputDataSet.drop([''ImagePath''], axis=1, inplace=True)
InputDataSet[''Place''] = predictions
InputDataSet[''Prob''] = probs
OutputDataSet = InputDataSet
',      
@input_data_1 = N'SELECT ImageID, ImagePath FROM dbo.PlaceImages WHERE PlaceDetected is null'    
;   
	  
UPDATE dbo.PlaceImages 
SET PlaceDetected = tb.Place, Probability = tb.Prob
FROM @MyTempTable AS tb
WHERE tb.ImageID = dbo.PlaceImages.ImageID

END
