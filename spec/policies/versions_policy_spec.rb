describe VersionsPolicy do
  let(:version_allowed) { described_class.version_allowed? user, version }
  let(:change_allowed) { described_class.change_allowed? user, item, field }

  let(:version) do
    build :version, item: item, item_diff: item_diff, user: author
  end
  let(:author) { user }
  let(:user) { seed :user }

  let(:item) { build_stubbed :anime }
  let(:item_diff) do
    {
      field => [change_from, change_to]
    }
  end
  let(:field) { :russian }
  let(:change_from) { 'a' }
  let(:change_to) { 'b' }

  it { expect(version_allowed).to eq true }
  it { expect(change_allowed).to eq true }

  context 'no user' do
    let(:user) { nil }
    it { expect(version_allowed).to eq false }
    it { expect(change_allowed).to eq false }
  end

  context 'user banned' do
    before { user.read_only_at = 1.hour.from_now }
    it { expect(version_allowed).to eq false }
    it { expect(change_allowed).to eq false }
  end

  context 'not_trusted_version_changer' do
    before { user.roles = %i[not_trusted_version_changer] }
    it { expect(version_allowed).to eq false }
    it { expect(change_allowed).to eq false }
  end

  context 'not_trusted_names_changer' do
    before { user.roles = %i[not_trusted_names_changer] }

    context 'not name field' do
      let(:field) { 'description_ru' }
      it { expect(version_allowed).to eq true }
      it { expect(change_allowed).to eq true }
    end

    context 'name field' do
      let(:field) do
        (
          Abilities::VersionNamesModerator::MANAGED_FIELDS -
            Anime::RESTRICTED_FIELDS
        ).sample
      end

      context 'not DbEntry model' do
        let(:item) { build_stubbed :video }
        it { expect(version_allowed).to eq true }
        it { expect(change_allowed).to eq true }
      end

      context 'DbEntry model' do
        it { expect(version_allowed).to eq false }
        it { expect(change_allowed).to eq false }
      end
    end
  end

  context 'not_trusted_texts_changer' do
    before { user.roles = %i[not_trusted_texts_changer] }

    context 'not text field' do
      let(:field) { 'russian' }
      it { expect(version_allowed).to eq true }
      it { expect(change_allowed).to eq true }
    end

    context 'text field' do
      let(:field) do
        (
          Abilities::VersionTextsModerator::MANAGED_FIELDS -
            Anime::RESTRICTED_FIELDS
        ).sample
      end

      context 'not DbEntry model' do
        let(:item) { build_stubbed :video }
        it { expect(version_allowed).to eq true }
        it { expect(change_allowed).to eq true }
      end

      context 'DbEntry model' do
        it { expect(version_allowed).to eq false }
        it { expect(change_allowed).to eq false }
      end
    end
  end

  context 'not_trusted_fansub_changer' do
    before { user.roles = %i[not_trusted_fansub_changer] }

    context 'not fansub field' do
      let(:field) { 'russian' }
      it { expect(version_allowed).to eq true }
      it { expect(change_allowed).to eq true }
    end

    context 'fansub field' do
      let(:field) { Abilities::VersionFansubModerator::MANAGED_FIELDS.sample }

      context 'not DbEntry model' do
        let(:item) { build_stubbed :video }
        it { expect(version_allowed).to eq true }
        it { expect(change_allowed).to eq true }
      end

      context 'DbEntry model' do
        it { expect(version_allowed).to eq false }
        it { expect(change_allowed).to eq false }
      end
    end
  end

  context 'not_trusted_videos_changer' do
    before { user.roles = %i[not_trusted_videos_changer] }

    context 'not videos field' do
      let(:field) { 'russian' }
      it { expect(version_allowed).to eq true }
      it { expect(change_allowed).to eq true }
    end

    context 'videos field' do
      let(:field) { Abilities::VersionVideosModerator::MANAGED_FIELDS.sample }

      context 'not DbEntry model' do
        let(:item) { build_stubbed :poster }
        it { expect(version_allowed).to eq true }
        it { expect(change_allowed).to eq true }
      end

      context 'DbEntry model' do
        it { expect(version_allowed).to eq false }
        it { expect(change_allowed).to eq false }
      end

      context 'video model' do
        let(:item) { build_stubbed :video }
        let(:field) { 'zxc' }

        it { expect(version_allowed).to eq false }
        it { expect(change_allowed).to eq false }
      end
    end
  end

  context 'not_trusted_images_changer' do
    before { user.roles = %i[not_trusted_images_changer] }

    context 'not images field' do
      let(:field) { 'russian' }
      it { expect(version_allowed).to eq true }
      it { expect(change_allowed).to eq true }
    end

    context 'videos field' do
      let(:field) { Abilities::VersionImagesModerator::MANAGED_FIELDS.sample }

      context 'not DbEntry model' do
        let(:item) { build_stubbed :video }
        it { expect(version_allowed).to eq true }
        it { expect(change_allowed).to eq true }
      end

      context 'DbEntry model' do
        it { expect(version_allowed).to eq false }
        it { expect(change_allowed).to eq false }
      end

      context 'poster model' do
        let(:item) { build_stubbed :poster }
        let(:field) { 'zxc' }

        it { expect(version_allowed).to eq false }
        it { expect(change_allowed).to eq false }
      end
    end
  end

  context 'not_trusted_links_changer' do
    before { user.roles = %i[not_trusted_links_changer] }

    context 'not links field' do
      let(:field) { 'russian' }
      it { expect(version_allowed).to eq true }
      it { expect(change_allowed).to eq true }
    end

    context 'links field' do
      let(:field) { Abilities::VersionLinksModerator::MANAGED_FIELDS.sample }

      context 'not DbEntry model' do
        let(:item) { build_stubbed :video }
        it { expect(version_allowed).to eq true }
        it { expect(change_allowed).to eq true }
      end

      context 'DbEntry model' do
        it { expect(version_allowed).to eq false }
        it { expect(change_allowed).to eq false }
      end
    end
  end

  context 'not matched author' do
    let(:author) { user_2 }
    it { expect(version_allowed).to eq false }
  end

  context 'changed restricted field' do
    context 'from nil to value' do
      let(:field) { :image }
      let(:change_from) { nil }

      it { expect(version_allowed).to eq true }
      it { expect(change_allowed).to eq true }
    end

    context 'from value to value' do
      let(:field) { :name }

      it { expect(version_allowed).to eq false }
      it { expect(change_allowed).to eq false }

      context 'version_names_moderator' do
        before { user.roles = %i[version_names_moderator] }

        it { expect(version_allowed).to eq true }
        it { expect(change_allowed).to eq true }
      end

      context 'version_texts_moderator' do
        before { user.roles = %i[version_texts_moderator] }

        it { expect(version_allowed).to eq false }
        it { expect(change_allowed).to eq false }
      end

      context 'version_moderator' do
        before { user.roles = %i[version_moderator] }

        it { expect(version_allowed).to eq false }
        it { expect(change_allowed).to eq false }

        context 'image' do
          let(:field) { :image }

          it { expect(version_allowed).to eq false }
          it { expect(change_allowed).to eq true }
        end
      end
    end
  end
end
