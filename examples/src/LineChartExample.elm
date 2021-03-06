module LineChartExample exposing (Model, Msg, init, update, view)

import Array
import Charty.LineChart as LineChart
import Html exposing (Html, div, text)
import Html.Attributes as Attributes
import Html.Events as Events
import Json.Decode as Decode
import Json.Encode as Encode
import Layout


type Msg
    = DatasetChange String
    | ToggleLabels
    | TogglePoints


type alias Model =
    { input : String
    , inputOk : Bool
    , dataset : LineChart.Dataset
    , drawPoints : Bool
    , drawLabels : Bool
    }


init : Model
init =
    { dataset = sampleDataset
    , input = encodeDataset sampleDataset
    , inputOk = True
    , drawPoints = True
    , drawLabels = True
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DatasetChange text ->
            case Decode.decodeString datasetDecoder text of
                Result.Ok dataset ->
                    ( { model | input = text, inputOk = True, dataset = dataset }, Cmd.none )

                Result.Err err ->
                    ( { model | input = text, inputOk = False }, Cmd.none )

        TogglePoints ->
            ( { model | drawPoints = not model.drawPoints }, Cmd.none )

        ToggleLabels ->
            ( { model | drawLabels = not model.drawLabels }, Cmd.none )


view : Model -> Html Msg
view model =
    let
        defaults =
            LineChart.defaults

        chart =
            LineChart.view
                { defaults
                    | drawPoints = model.drawPoints
                    , drawLabels = model.drawLabels
                }
                model.dataset

        opacity =
            if model.inputOk then
                1
            else
                0.3

        toggle msg getter field =
            Html.p
                []
                [ Html.input
                    [ Attributes.type_ "checkbox"
                    , Attributes.checked (getter model)
                    , Attributes.id ("toggle-" ++ field)
                    , Events.onCheck (always msg)
                    ]
                    []
                , Html.label
                    [ Attributes.for ("toggle-" ++ field) ]
                    [ Html.text ("display " ++ field) ]
                ]
    in
        Layout.twoColumns
            [ Html.p [] [ Html.text "The dataset below will be displayed on the right upon validation." ]
            , Html.div
                [ Attributes.class "config-section" ]
                [ Html.div [ Attributes.class "title" ] [ text "Settings" ]
                , toggle TogglePoints .drawPoints "points"
                , toggle ToggleLabels .drawLabels "labels"
                ]
            , Html.div
                [ Attributes.class "config-section" ]
                [ Html.div [ Attributes.class "title", Attributes.style [ ( "flex-grow", "1" ) ] ] [ text "Data" ]
                , Html.textarea
                    [ Attributes.class "dataset-editor"
                    , Attributes.style [ ( "height", "50vh" ) ]
                    , Events.onInput DatasetChange
                    ]
                    [ Html.text model.input ]
                ]
            ]
            (Html.div
                [ Attributes.style [ ( "opacity", toString opacity ) ] ]
                [ chart ]
            )


sampleDataset : LineChart.Dataset
sampleDataset =
    [ { label = "Series 1"
      , data = [ ( 100000, 3 ), ( 100001, 4 ), ( 100002, 3 ), ( 100003, 2 ), ( 100004, 1 ), ( 100005, 1 ), ( 100006, -1 ) ]
      }
    , { label = "Series 2"
      , data = [ ( 100000, 1 ), ( 100001, 2.5 ), ( 100002, 3 ), ( 100003, 3.5 ), ( 100004, 3 ), ( 100005, 2 ), ( 100006, 0 ) ]
      }
    , { label = "Series 3"
      , data = [ ( 100000, 2 ), ( 100001, 1.5 ), ( 100002, 0 ), ( 100003, 3 ), ( 100004, -0.5 ), ( 100005, -1.5 ), ( 100006, -2 ) ]
      }
    ]


encodeDataset : LineChart.Dataset -> String
encodeDataset dataset =
    let
        entryEncoder =
            \( x, y ) -> Encode.array (Array.fromList [ Encode.float x, Encode.float y ])

        seriesEncoder series =
            Encode.object
                [ ( "label", Encode.string series.label )
                , ( "data", series.data |> List.map entryEncoder |> Encode.list )
                ]

        datasetEncoder =
            List.map seriesEncoder >> Encode.list
    in
        Encode.encode 4 (datasetEncoder dataset)


datasetDecoder : Decode.Decoder LineChart.Dataset
datasetDecoder =
    let
        arrayToTuple a =
            case Array.toList a of
                x :: y :: [] ->
                    Decode.succeed ( x, y )

                _ ->
                    Decode.fail "Failed to decode point"

        entryDecoder =
            Decode.array Decode.float |> Decode.andThen arrayToTuple

        seriesDecoder =
            Decode.map2 (\label data -> { label = label, data = data })
                (Decode.field "label" Decode.string)
                (Decode.field "data" (Decode.list entryDecoder))
    in
        Decode.list <| seriesDecoder
