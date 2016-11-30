module State exposing (..)

import Messages exposing (Msg(..))
import Types exposing (Model)
import Deployments.State
import Aliases.Rest exposing (fetchAliases)
import Deployments.Rest exposing (fetchDeployments)
import Aliases.State
import Secrets.State exposing (update)
import Login.View
import Navigation
import Ports exposing (..)
import String
import Routing


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        DeploymentsMsg subMsg ->
            let
                ( updatedDeployments, cmd ) =
                    Deployments.State.update subMsg
                        { deployments = model.deployments.deployments
                        , token = model.login.token
                        , aliases = model.aliases
                        , editMode = model.deployments.editMode
                        , requests = model.deployments.requests
                        , autocompleteMode = model.deployments.autocompleteMode
                        }
            in
                ( { model | deployments = updatedDeployments, aliases = updatedDeployments.aliases }, Cmd.map DeploymentsMsg cmd )

        AliasesMsg subMsg ->
            let
                ( updatedAliases, cmd ) =
                    Aliases.State.update subMsg model.aliases
            in
                ( { model | aliases = updatedAliases }, Cmd.map AliasesMsg cmd )

        SecretsMsg subMsg ->
            let
                ( updatedSecrets, cmd ) =
                    Secrets.State.update subMsg model.secrets
            in
                ( { model | secrets = updatedSecrets }, Cmd.map SecretsMsg cmd )

        AboutMsg subMsg ->
            ( model, Cmd.none )

        LoginMsg subMsg ->
            let
                ( updatedLogin, cmd ) =
                    Login.View.update subMsg model.login
            in
                ( { model | login = updatedLogin }, Cmd.map LoginMsg cmd )

        LogoutMsg ->
            let
                newLogin =
                    model.login
            in
                ( { model
                    | login =
                        { newLogin
                            | isLoggedIn = False
                            , token = ""
                            , errorMessage = ""
                        }
                  }
                , Cmd.batch
                    [ Navigation.newUrl "/#/login"
                    , setToken ""
                    ]
                )

        Start_Load_Token ->
            ( model, startLoadToken () )

        Load_Token token ->
            if String.isEmpty token then
                ( model, Navigation.newUrl "/#/login" )
            else
                let
                    newLogin =
                        model.login
                in
                    ( { model
                        | login =
                            { newLogin
                                | isLoggedIn = True
                                , token = token
                                , errorMessage = ""
                            }
                      }
                    , Cmd.batch
                        [ Cmd.map DeploymentsMsg (fetchDeployments token)
                        , Cmd.map AliasesMsg (fetchAliases token)
                        , Navigation.newUrl "/#/deployments"
                        ]
                    )

        GoTo route ->
            case route of
                Nothing ->
                    ( { model | route = Routing.DeploymentsRoute }, Cmd.none )

                Just route ->
                    ( { model | route = route }, Cmd.map DeploymentsMsg (fetchDeployments model.login.token) )