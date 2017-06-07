module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import RemoteData exposing (WebData, RemoteData(..))
import Http
import Json.Decode as JD
import Array exposing (Array)


-- MODEL


type alias Model =
    { content : String
    , matrixs : WebData (List Matrix)
    , page : Page
    , matrixBuilder : List (List Cell)
    }



--Idea for data structure to back the matrix builder ui


type alias ActiveMatrix =
    { colCount : Int
    , rowCount : Int
    , cells : Array (Array Cell)
    , title : String
    , slug : String
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


initModel : Model
initModel =
    { content = "Hello!"
    , matrixs = NotAsked
    , page = MakeMatrix
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


link : Page -> String -> Html Msg
link page text_ =
    li []
        [ a [ onClick <| Visit page, href "#" ]
            [ text text_ ]
        ]


nav : List (Html Msg)
nav =
    [ ul []
        [ link Home "Home"
        , link MakeMatrix "Make a Matrix"
        ]
    ]


basePage : Html Msg -> Html Msg
basePage child =
    nav
        ++ [ child ]
        |> div []


homePage : Model -> Html Msg
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


matrix : Matrix -> Html Msg
matrix m =
    div []
        [ h1 [] [ text m.name ]
        , table [] <|
            [ tr [] (List.map (\n -> td [] [ text n ]) ([ "" ] ++ m.col_names)) ]
                ++ (List.map2 row m.grid m.row_names)
        ]


row : List String -> String -> Html Msg
row names row_name =
    tr [] <|
        [ td [] [ text row_name ] ]
            ++ (List.map (\n -> td [] [ text n ]) names)


makeMatrixPage : Model -> Html Msg
makeMatrixPage model =
    div []
        [ h1 [] [ text "Make a Matrix" ]
        , matrixBuild model
        , button [] [ text "Share it" ]
        , p [] [ text "the link to share" ]
        ]
        |> basePage


matrixBuild : Model -> Html Msg
matrixBuild model =
    table []
        (List.map initBuild model.matrixBuilder)


initBuild : List Cell -> Html Msg
initBuild cells =
    (List.map tdcell cells)
        |> tr []


tdcell : Cell -> Html Msg
tdcell c =
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


main : Program Never Model Msg
main =
    Html.program
        { init = model
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
