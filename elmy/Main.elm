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
    , matrixBuilder : List (List Cell)
    }


type Page
    = Home
    | MakeMatrix


type Cell
    = AddRow
    | AddCol
    | ReqName
    | Wink
    | Todo


initModel =
    { content = "Hello!"
    , matrixs = NotAsked
    , page = Home
    , matrixBuilder =
        [ [ Wink, ReqName, AddCol ]
        , [ ReqName, Todo, Todo ]
        , [ AddRow, Todo, Todo ]
        ]
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
    | ColAdded
    | RowAdded


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MatrixsResp matrixs ->
            ( { model | matrixs = matrixs }, Cmd.none )

        Visit page ->
            ( { model | page = page }, Cmd.none )

        RowAdded ->
            let
                matrixBuilder_ =
                    model.matrixBuilder ++ [ [ AddRow, Todo, Todo ] ]
            in
                { model | matrixBuilder = matrixBuilder_ } ! []

        ColAdded ->
            model ! []



-- VIEW


view : Model -> Html Msg
view model =
    case model.page of
        Home ->
            homePage model

        MakeMatrix ->
            makeMatrixPage model


link page text_ =
    li []
        [ a [ onClick <| Visit page, href "#" ]
            [ text text_ ]
        ]


nav =
    [ ul []
        [ link Home "Home"
        , link MakeMatrix "Make a Matrix"
        ]
    ]


basePage child =
    nav
        ++ [ child ]
        |> div []


homePage model =
    basePage <|
        case model.matrixs of
            Loading ->
                text "LOADING"

            Success matrixs ->
                div [] (matrixs |> List.map matrix)

            NotAsked ->
                p [ style [ ( "background", "#eee" ), ( "padding", "2em" ) ] ] [ text "Loading..." ]

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


makeMatrixPage model =
    div []
        [ h1 [] [ text "Make a Matrix" ]
        , matrixBuild model
        , button [] [ text "Share it" ]
        , p [] [ text "the link to share" ]
        ]
        |> basePage


matrixBuild model =
    table []
        (List.map initBuild model.matrixBuilder)


initBuild row =
    (List.map cell row)
        |> tr []


cell : Cell -> Html Msg
cell c =
    case c of
        Wink ->
            td [] [ text ";)" ]

        ReqName ->
            td [] [ input [ type_ "text" ] [] ]

        AddRow ->
            td [] [ button [ onClick RowAdded ] [ text "v" ] ]

        AddCol ->
            td [] [ button [ onClick ColAdded ] [ text "+" ] ]

        Todo ->
            td [] []



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
