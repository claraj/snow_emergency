# Cut down version

import requests, csv, time

key = 'ORS KEY GOES HERE'
file = 'data/SNOW_TAG_TOW_TYPES.csv'

def get_driving(location):  # end in the format of = '-95.4545,45.343' 
    distance_url = 'https://api.openrouteservice.org/v2/directions/driving-car'
    impound_lot = '-93.291796,44.977125'  
    params = { 'api_key': key , 'start': location, 'end': impound_lot }
    try: 
        response = requests.get( distance_url, params = params).json()
        return response['features'][0]['properties']['summary']
    except Exception as e:
        print(e)
        return None  # Caller will use this to know if the request has been rejected.

counter = 1  # For slowing down the request rate 

with open(file) as csvfile:
    reader = csv.reader(csvfile, delimiter=',')
    header = reader.__next__() 
    rows = list(reader)    
    try:
        for row in rows:
            distance = row[15]
            drivetime = row[16]
            if distance and drivetime:
                continue

            time.sleep(2)       # Throttle requests or get blocked after ~40 requests. 
            counter += 1
            if counter == 30:
                time.sleep(10)
                counter = 0

            loc = f'{row[1]},{row[2]}'
            driving = get_driving(loc)
           
            if driving:
                row[15] = str(driving['distance'])
                row[16] = str(driving['duration'])
            else:
                break 
    except Exception as e:
        print("error", e)
        pass 
        
with open(file, 'w') as csvfile:  # Write all the data to the CSV file 
    writer = csv.writer(csvfile, delimiter=',')
    writer.writerow(header)
    for row in rows:
        writer.writerow(row)

    