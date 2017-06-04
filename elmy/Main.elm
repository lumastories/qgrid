module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (..)
import RemoteData exposing (..)
import Http
import Json.Decode as JD


-- MODEL


type alias Model =
    { content : String
    , matrixs : WebData (List Matrix)
    }


initModel =
    { content = "Hello!"
    , matrixs = NotAsked
    }


model : ( Model, Cmd Msg )
model =
    ( initModel, Cmd.batch [ getMatrixs ] )


type alias Matrix =
    { name : String
    , grid : List (List String)
    , row_names : List String
    , col_names : List String
    }



-- HTTP


getMatrixs : Cmd Msg
getMatrixs =
    Http.get "/api/matrix" decodeMatrix
        |> RemoteData.sendRequest
        |> Cmd.map MatrixsResp


decodeMatrix : JD.Decoder (List Matrix)
decodeMatrix =
    JD.list <|
        JD.map4 Matrix
            (JD.field "name" JD.string)
            (JD.field "grid" <| JD.list <| JD.list JD.string)
            (JD.field "row_names" <| JD.list <| JD.string)
            (JD.field "col_names" <| JD.list <| JD.string)



-- UPDATE


type Msg
    = Reset
    | MatrixsResp (WebData (List Matrix))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MatrixsResp matrixs ->
            ( { model | matrixs = matrixs }, Cmd.none )

        _ ->
            ( model, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    case model.matrixs of
        Loading ->
            text "Loading..."

        Success matrixs ->
            div [] (matrixs |> List.map matrix)

        _ ->
            text ""


matrix m =
    div []
        [ h1 [] [ text m.name ]
        , table [] <|
            [tr [] (List.map (\n -> td [] [ text n ]) ([""] ++ m.col_names))]
            ++ (List.map2 row m.grid m.row_names)
        ]

row names row_name =  
    tr [] <| [td [] [text row_name]] ++ (List.map (\n -> td [] [ text n ]) names)


{--

grid = [["text00","text01","text02"]
       ,["text10","text11","text12"]
       ,["text20","text21","text22"]],

row_names = ["row0","row1","row2"],

col_names = ["col0","col1","col2"]

--}



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- APP


main =
    Html.program
        { init = model
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
