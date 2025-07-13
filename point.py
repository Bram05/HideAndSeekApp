from math import pi, cos, sin
def point(lat, lon):
    theta = lat/180*pi
    phi = lon/180*pi
    return (cos(lat)*sin(phi), sin(theta)*sin(phi), cos(phi))

print(point(52.3599, 4.8850))
print(point(52.3584, 4.8834))

print(point(52.3591, 4.8842))
print(point(52.3575, 4.8856))
