defmodule Metamorphic.EctoEnums do
  @moduledoc """
  Define Ecto enumerables for Metamorphic.

  Current enumerable consists of privileges for people
  to grant and restrict access within the application.

  By default, a newly registered account is assigned the :person
  privilege, which grants normal (non-administrative) access.
  """
  import EctoEnum
  defenum(PrivilegesEnum, :privileges, [:admin, :person])
  defenum(RoadmapFeaturesEnum, :stages, [:horizon, :planning, :active])
end
