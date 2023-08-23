describe DbEntry::MergeIntoOther do
  subject { described_class.call entry: entry, other: other }

  %i[anime manga ranobe character person].each do |type|
    context type.to_s do
      is_animanga = type.in? %i[anime manga ranobe]
      is_anime = type == :anime

      let(:entry) do
        create type, :with_topics, {
          **(is_anime ? {
            fansubbers: %w[fansubber_1 fansubber_3],
            fandubbers: %w[fandubber_1 fandubber_3],
            coub_tags: %w[coub_tag_1 coub_tag_3]
          } : {}),
          **(is_animanga ? {
            synonyms: %w[synonym_1 synonym_3]
          } : {}),
          russian: 'zxc'
        }
      end
      let(:other) do
        create type, {
          **(is_anime ? {
            fansubbers: %w[fansubber_2],
            fandubbers: %w[fandubber_2],
            coub_tags: %w[coub_tag_2]
          } : {}),
          **(is_animanga ? {
            synonyms: %w[synonym_2]
          } : {}),
          russian: ''
        }
      end
      let(:entry_3) { create type }

      if is_animanga
        let!(:user_1_rate_entry) do
          create :user_rate, user_1_rate_entry_status, target: entry, user: user_1
        end
        let(:user_1_rate_entry_status) { :planned }
        let!(:user_1_rate_other) do
          create :user_rate, user_1_rate_other_status, target: other, user: user_1
        end
        let(:user_1_rate_other_status) { :planned }
        let!(:user_2_rate_entry) { create :user_rate, target: entry, user: user_2 }

        let!(:user_1_rate_log_entry) { create :user_rate_log, target: entry, user: user_1 }
        let!(:user_1_rate_log_other) { create :user_rate_log, target: other, user: user_1 }
        let!(:user_2_rate_log_entry) { create :user_rate_log, target: entry, user: user_2 }

        let!(:user_1_history_entry) do
          create :user_history, (entry.anime? ? :anime : :manga) => entry, user: user_1
        end
        let!(:user_1_history_other) do
          create :user_history, (other.anime? ? :anime : :manga) => other, user: user_1
        end
        let!(:user_2_history_entry) do
          create :user_history, (entry.anime? ? :anime : :manga) => entry, user: user_2
        end

        let!(:critique) { create :critique, target: entry }
        let!(:review) { create :review, "#{entry.anime? ? :anime : :manga}": entry }
        let!(:cosplay_gallery_link) do
          create :cosplay_gallery_link, linked: entry, cosplay_gallery: cosplay_gallery
        end
        let!(:recommendation_ignore) { create :recommendation_ignore, target: entry }
      end

      let!(:topic_1) { create :topic, linked: entry }
      let!(:topic_2) { create :topic, linked: entry, generated: true }

      let!(:poster_1) { create :poster, (type == :ranobe ? :manga : type) => entry }

      let!(:comment_1) { create :comment, :with_increment_comments, commentable: entry.maybe_topic }

      let(:collection) { create :collection }
      let!(:collection_link) { create :collection_link, linked: entry, collection: collection }

      let!(:version) { create :version, item: entry }

      let(:club) { create :club }
      let!(:club_link) { create :club_link, linked: entry, club: club }

      let(:cosplay_gallery) { create :cosplay_gallery }

      let!(:contest) { create :contest }
      let!(:contest_link) { create :contest_link, linked: entry, contest: contest }
      let!(:contest_winner) { create :contest_winner, item: entry, contest: contest }
      let!(:contest_match_1) { create :contest_match, left: entry, right: entry_3 }
      let!(:contest_match_2) do
        create :contest_match, left: entry_3, right: entry, winner_id: entry.id
      end

      let!(:anime_link) do
        create :anime_link, anime: entry, identifier: 'zxc' if is_anime
      end

      let!(:favourite_1_1) do
        create :favourite,
          linked_id: entry.id,
          linked_type: entry.class.name,
          user: user_1
      end
      let!(:favourite_1_2) do
        create :favourite,
          linked_id: other.id,
          linked_type: other.class.name,
          user: user_1
      end
      let!(:favourite_2_1) do
        create :favourite,
          linked_id: entry.id,
          linked_type: entry.class.name,
          user: user_2
      end

      if is_animanga
        let!(:external_link_1_1) { create :external_link, entry: entry, url: 'https://a.com/' }
        let!(:external_link_1_2) { create :external_link, entry: entry, url: 'http://b.com' }
        let!(:external_link_2_1) { create :external_link, entry: other, url: 'http://a.com' }
      end

      it do
        is_expected.to eq true

        expect(other.russian).to eq entry.russian
        expect(other.synonyms).to eq %w[synonym_1 synonym_2 synonym_3] if is_animanga
        if is_anime
          expect(other.fansubbers).to eq %w[fansubber_1 fansubber_2 fansubber_3]
          expect(other.fandubbers).to eq %w[fandubber_1 fandubber_2 fandubber_3]
          expect(other.coub_tags).to eq %w[coub_tag_1 coub_tag_2 coub_tag_3]
        end

        expect { entry.reload }.to raise_error ActiveRecord::RecordNotFound

        if is_animanga
          expect { user_1_rate_entry.reload }.to raise_error ActiveRecord::RecordNotFound
          expect { user_1_rate_log_entry.reload }.to raise_error ActiveRecord::RecordNotFound
          expect { user_1_history_entry.reload }.to raise_error ActiveRecord::RecordNotFound

          expect(user_1_rate_other.reload).to be_persisted
          expect(user_1_rate_log_other.reload).to be_persisted
          expect(user_1_history_other.reload).to be_persisted

          expect(user_2_rate_entry.reload.target).to eq other
          expect(user_2_rate_log_entry.reload.target).to eq other
          expect(user_2_history_entry.reload.target).to eq other
        end

        expect(topic_1.reload.linked).to eq other
        expect { topic_2.reload }.to raise_error ActiveRecord::RecordNotFound

        expect(poster_1.reload.target).to eq other
        expect(comment_1.reload.commentable).to eq other.maybe_topic
        expect(other.maybe_topic.comments_count).to eq 1

        if is_animanga
          expect(critique.reload.target).to eq other
          expect(review.reload.db_entry).to eq other
          expect(cosplay_gallery_link.reload.linked).to eq other
          expect(recommendation_ignore.reload.target).to eq other
        end

        expect(collection_link.reload.linked).to eq other
        expect(version.reload.item).to eq other
        expect(club_link.reload.linked).to eq other

        expect(contest_link.reload.linked).to eq other
        expect(contest_winner.reload.item).to eq other
        expect(contest_match_1.reload.left).to eq other
        expect(contest_match_2.reload.right).to eq other
        expect(contest_match_2.winner_id).to eq other.id

        if entry.respond_to? :anime_links
          expect(anime_link.reload.anime).to eq other
        end

        expect { favourite_1_1.reload }.to raise_error ActiveRecord::RecordNotFound
        expect(favourite_2_1.reload.linked).to eq other

        if is_animanga
          expect { external_link_1_1.reload }.to raise_error ActiveRecord::RecordNotFound
          expect(external_link_1_2.reload.entry).to eq other
        end
      end

      if is_animanga
        describe 'user_rate' do
          context 'entry is completed' do
            let(:user_1_rate_entry_status) { :completed }

            it do
              is_expected.to eq true

              expect(user_1_rate_entry.reload.target).to eq other
              expect(user_1_rate_log_entry.reload.target).to eq other
              expect(user_1_history_entry.reload.target).to eq other

              expect { user_1_rate_other.reload }.to raise_error ActiveRecord::RecordNotFound
              expect { user_1_rate_log_other.reload }.to raise_error ActiveRecord::RecordNotFound
              expect { user_1_history_other.reload }.to raise_error ActiveRecord::RecordNotFound
            end

            context 'no other rate' do
              let!(:user_1_rate_other) { nil }
              let!(:user_1_rate_log_other) { nil }
              let!(:user_1_history_other) { nil }

              it do
                is_expected.to eq true

                expect(user_1_rate_entry.reload.target).to eq other
                expect(user_1_rate_log_entry.reload.target).to eq other
                expect(user_1_history_entry.reload.target).to eq other
              end
            end

            context 'other is completed' do
              let(:user_1_rate_other_status) { :completed }

              it do
                is_expected.to eq true

                expect { user_1_rate_entry.reload }.to raise_error ActiveRecord::RecordNotFound
                expect { user_1_rate_log_entry.reload }.to raise_error ActiveRecord::RecordNotFound
                expect { user_1_history_entry.reload }.to raise_error ActiveRecord::RecordNotFound

                expect(user_1_rate_other.reload).to be_persisted
                expect(user_1_rate_log_other.reload).to be_persisted
                expect(user_1_history_other.reload).to be_persisted
              end
            end
          end
        end
      end
    end
  end
end
