module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import RemoteData exposing (..)
import Http
import Json.Decode as JD


-- MODEL


type alias Model =
    { content : String
    , matrixs : WebData (List Matrix)
    , page : Page
    }


type Page
    = Home
    | MakeMatrix


initModel =
    { content = "Hello!"
    , matrixs = NotAsked
    , page = Home
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
    = Visit Page
    | MatrixsResp (WebData (List Matrix))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MatrixsResp matrixs ->
            ( { model | matrixs = matrixs }, Cmd.none )

        Visit page ->
            ( { model | page = page }, Cmd.none )



-- VIEW


view : Model -> Html Msg
view model =
    case model.page of
        Home ->
            homePage model

        MakeMatrix ->
            makeMatrixPage model


link page text_ =
    a [ onClick <| Visit page, href "#" ] [ text text_ ]


basePage child =
    div [] [ link Home "Home", link MakeMatrix "Make a Matrix", child ]


makeMatrixPage model =
    div [] [ h1 [] [ text "Make a Matrix" ]
            , button [] [text "Add row"]
            , button [] [text "Add column"] ]
        |> basePage


homePage model =
    basePage <|
        case model.matrixs of
            Loading ->
                text "LOADING"

            Success matrixs ->
                div [] (matrixs |> List.map matrix)

            NotAsked ->
                p [ style [ ( "background", "red" ) ] ] [ text "Loading..." ]

            Failure _ ->
                text "Request failed :("


matrix m =
    div []
        [ h1 [] [ text m.name ]
        , table [] <|
            [ tr [] (List.map (\n -> td [] [ text n ]) ([ "" ] ++ m.col_names)) ]
                ++ (List.map2 row m.grid m.row_names)
        ]


row names row_name =
    tr [] <|
        [ td [] [ text row_name ] ]
            ++ (List.map (\n -> td [] [ text n ]) names)



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
