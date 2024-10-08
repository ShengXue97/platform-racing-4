package pr2_level_import

import (
	"reflect"
	"testing"
)

func TestParseLine(t *testing.T) {
	lineStr := "30;27;12;15"
	color := "0"
	thickness := 5
	mode := "paintbrush"

	expected := ArtObject{
		X: 128,
		Y: 115,
		Polyline: []Point{
			{X: 0, Y: 0},
			{X: 51, Y: 64},
		},
		Properties: LineProperties{
			Color:     "000000",
			Thickness: 21,
			Mode:      mode,
		},
	}

	result := parseLine(lineStr, color, thickness, mode)
	if !reflect.DeepEqual(result, expected) {
		t.Errorf("Expected %+v, got %+v", expected, result)
	}
}
