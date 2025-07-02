defmodule Tunez.Music.Artist do
  use Ash.Resource,
    otp_app: :tunez,
    domain: Tunez.Music,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshGraphql.Resource, AshJsonApi.Resource],
    authorizers: [Ash.Policy.Authorizer]

  graphql do
    type :artist

    filterable_fields [
      :album_count,
      :cover_image_url,
      :inserted_at,
      :latest_album_year_released,
      :updated_at
    ]

    derive_filter? false
    derive_sort? false
  end

  json_api do
    type "artist"
    includes albums: [:tracks]
    derive_filter? false
  end

  postgres do
    table "artists"
    repo Tunez.Repo

    custom_indexes do
      index "name gin_trgm_ops", name: "artists_name_gin_index", using: "GIN"
    end
  end

  resource do
    description "A person or group of people that makes and releases music."
  end

  actions do
    defaults [:read, :create]
    default_accept [:name, :biography]

    read :search do
      description "List Artists, optionally filtering by name."

      argument :query, :ci_string do
        description "Return only artists with names including the given value."
        constraints allow_empty?: true
        default ""
      end

      # prepare build(load: [:album_count, :latest_album_year_released, :cover_image_url])
      filter expr(contains(^ref(:name), ^arg(:query)))
      pagination keyset?: true, default_limit: 12
    end

    update :update do
      accept [:name, :biography]
      # NOTE: this is needed if we use the validations below.
      # already atomic in UpdatePreviousNames, but require_atomic? false is
      # needed in validations, because validations aren't changes.
      # validations aren't part of the single db transaction, because it
      # operates in the app (Elixir) level.
      # require_atomic? false

      change Tunez.Music.Changes.UpdatePreviousNames
    end

    destroy :destroy do
      primary? true
      change cascade_destroy(:albums, return_notifications?: true, after_action?: false)
    end
  end

  policies do
    bypass actor_attribute_equals(:role, :admin) do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if always()
      # authorize_if expr(secret === false)
      # authorize_if actor_attribute_equals(:role, :admin)
    end

    policy action_type(:update) do
      forbid_if always()
    end

    policy action(:create) do
      forbid_if always()
    end

    policy action(:destroy) do
      forbid_if always()
    end
  end

  changes do
    change relate_actor(:created_by, allow_nil?: true), on: [:create]
    change relate_actor(:updated_by, allow_nil?: true)
  end

  # NOTE: you need `require_atomic? false` in order to use this.
  # add it in `update :update do...`, because this is not part
  # of a single db transactions, hence not atomic operation.
  # validations do
  #   validate Tunez.Music.Validations.ValidatePreviousNames,
  #     where: [changing(:name)],
  #     before_action?: true
  # end

  attributes do
    uuid_primary_key :id

    attribute :previous_names, {:array, :string} do
      default []
      public? true
    end

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :biography, :string do
      public? true
    end

    create_timestamp :inserted_at, public?: true
    update_timestamp :updated_at, public?: true
  end

  relationships do
    belongs_to :created_by, Tunez.Accounts.User
    belongs_to :updated_by, Tunez.Accounts.User

    has_many :follower_relationships, Tunez.Music.ArtistFollower

    many_to_many :followers, Tunez.Accounts.User do
      # through Tunez.Music.ArtistFollower # alternative to join_relationship
      join_relationship :follower_relationships
      destination_attribute_on_join_resource :follower_id
    end

    has_many :albums, Tunez.Music.Album do
      sort year_released: :desc
      public? true
    end
  end

  calculations do
    # calculate :album_count, :integer, expr(count(albums))
    # calculate :latest_album_year_released, :integer, expr(first(albums, field: :year_released))
    # calculate :cover_image_url, :string, expr(first(albums, field: :cover_image_url))
    calculate :name_length, :integer, expr(string_length(name))
    # calculate :name_length, :integer, expr(fragment("length(?)", name))
    calculate :followed_by_me,
              :boolean,
              expr(exists(follower_relationships, follower_id == ^actor(:id))) do
      public? true
    end
  end

  aggregates do
    count :album_count, :albums do
      public? true
    end

    first :latest_album_year_released, :albums, :year_released do
      public? true
    end

    first :cover_image_url, :albums, :cover_image_url do
      public? true
    end

    count :follower_count, :follower_relationships do
      public? true
    end
  end
end
