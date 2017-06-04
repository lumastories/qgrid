module Main exposing (..)

import Html exposing (..)
import Html.Events exposing (..)

-- MODEL

type alias Model = 
  { content : String 
  }


model : (Model, Cmd Msg)
model =
  (Model "Hello!", Cmd.none)


-- UPDATE

type Msg
  = Reset

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Reset ->
      (model, Cmd.none)


-- VIEW

view : Model -> Html Msg
view model =
  h1 [] [ text model.content ]


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
