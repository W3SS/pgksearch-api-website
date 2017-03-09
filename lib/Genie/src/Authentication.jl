module Authentication

using SearchLight, App, Genie, Sessions

export current_user, current_user!!

const USER_ID_KEY = :__auth_user_id

function authenticate(user_id::Any, session) :: Sessions.Session
  Sessions.set!(session, USER_ID_KEY, user_id)
end
function authenticate(user_id::Any, params::Dict{Symbol,Any}) :: Sessions.Session
  authenticate(user_id, params[:SESSION])
end

function deauthenticate(session) :: Sessions.Session
  Sessions.unset!(session, USER_ID_KEY)
end
function deauthenticate(params::Dict{Symbol,Any}) :: Sessions.Session
  deauthenticate(params[:SESSION])
end

function is_authenticated(session) :: Bool
  Sessions.is_set(session, USER_ID_KEY)
end
function is_authenticated(params::Dict{Symbol,Any}) :: Bool
  is_authenticated(params[:SESSION])
end

function get_authentication(session)
  Sessions.get(session, USER_ID_KEY)
end
function get_authentication(params::Dict{Symbol,Any})
  get_authentication(params[:SESSION])
end

function login(user, session) :: Nullable{Sessions.Session}
  authenticate(getfield(user, Symbol(user._id)) |> Base.get, session) |> Nullable{Sessions.Session}
end
function login(user, params::Dict{Symbol,Any}) :: Nullable{Sessions.Session}
  login(user, params[:SESSION])
end

function logout(session) :: Sessions.Session
  deauthenticate(session)
end
function logout(params::Dict{Symbol,Any}) :: Sessions.Session
  logout(params[:SESSION])
end

function current_user(session) :: Nullable{User}
  auth_state = Authentication.get_authentication(session)
  if isnull(auth_state)
    Nullable{User}()
  else
    SearchLight.find_one(User, Base.get(auth_state))
  end
end
function current_user(params::Dict{Symbol,Any}) :: Nullable{User}
  current_user(params[:SESSION])
end

function current_user!!(session) :: User
  try
    current_user(session) |> Base.get
  catch ex
    Logger.log("The current user is not authenticated", :err)
    rethrow(ex)
  end
end
function current_user!!(params::Dict{Symbol,Any}) :: User
  current_user!!(params[:SESSION])
end

function with_authentication(f::Function, fallback::Function, session)
  if ! is_authenticated(session)
    fallback()
  else
    f()
  end
end
function with_authentication(f::Function, fallback::Function, params::Dict{Symbol,Any})
  with_authentication(f, fallback, params[:SESSION])
end

function without_authentication(f::Function, session)
  ! is_authenticated(session) && f()
end
function without_authentication(f::Function, params::Dict{Symbol,Any})
  without_authentication(f, params[:SESSION])
end

end
