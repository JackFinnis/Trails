import json
import itertools
# import geopy.distance

# from pyproj import Transformer
# transformer = Transformer.from_crs(27700, 4326)

# newLines = []
# while lines:
#     line = lines.pop()
#     flag = True
#     while flag:
#         flag = False
#         for l in lines.copy():
#             if line[-1] == l[0]:
#                 line = line + l
#                 lines.remove(l)
#                 flag = True
#             elif line[-1] == l[-1]:
#                 line = line + l[::-1]
#                 lines.remove(l)
#                 flag = True
#             elif line[0] == l[0]:
#                 line = line[::-1] + l
#                 lines.remove(l)
#                 flag = True
#             elif line[0] == l[-1]:
#                 line = l + line
#                 lines.remove(l)
#                 flag = True
#     newLines.append(line)



# for feature in features:
#     trail = {}
#     properties = feature['properties']

#     trail['coords'] = [[[round(x, 5) for x in coord][::-1] for coord in coords] for coords in feature['geometry']['coordinates']]
#     trail['name'] = properties['NAME']
#     trail['start'] = ""
#     trail['end'] = ""

#     metres = 0.0
#     for coords in trail['coords']:
#         for i in range(0, len(coords)-2):
#             metres += geopy.distance.geodesic(coords[i], coords[i+1]).meters
#     trail['metres'] = round(metres)
#     trails.append(trail)

with open('files.txt', 'r') as f:
    files = f.read().split('\n')

for file in files:
    with open(f'Hiiker/{file}', 'r') as f:
        geojson = json.load(f)
    print(file, geojson['features'][0]['properties']['totalElevation'])

# for feature in features:
#     print(feature['id'], len(list(itertools.chain.from_iterable(feature['lines']))))

# with open('Coords.geojson', 'w') as f:
#     json.dump(geojson, f)

# with open('Coast1.json', 'w') as f:
#     json.dump([line[0::5] for line in lines], f)

# features = []
# for trail in trails:
#     feature = {}
#     feature['type'] = "Feature"
#     properties = {}
#     properties['id'] = trail['id']
#     feature['properties'] = properties
#     geometry = {}
#     geometry['type'] = "MultiLineString"
#     geometry['coordinates'] = [[coord[::-1] for coord in line] for line in trail['lines']]
#     feature['geometry'] = geometry
#     features.append(feature)

# geojson = {}
# geojson['type'] = "FeatureCollection"
# geojson['features'] = features

# with open('Coords.geojson', 'w') as f:
#     json.dump(geojson, f)