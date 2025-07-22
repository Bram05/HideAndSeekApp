#include "Expose.h"
#include "Shape.h"

int main() {
    Shape* s = new Shape({
		Segment({
			{LatLng(0, 0), LatLng(1, 1)},
			{std::make_shared<StraightSide>(LatLng(0, 0), LatLng(1, 1))}
		})
	});
}
