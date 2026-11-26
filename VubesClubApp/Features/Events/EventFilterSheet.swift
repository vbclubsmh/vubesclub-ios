import SwiftUI

struct EventFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var filter: EventFilter

    var body: some View {
        NavigationStack {
            Form {
                Picker(L("Sport"), selection: $filter.sport) {
                    Text(L("All sports")).tag(nil as Sport?)

                    ForEach(Sport.allCases, id: \.self) { sport in
                        Text(L(sport.rawValue)).tag(Optional(sport))
                    }
                }

                Picker(L("Level"), selection: $filter.level) {
                    Text(L("All levels")).tag(nil as EventLevel?)

                    ForEach(EventLevel.allCases, id: \.self) { level in
                        Text(L(level.rawValue)).tag(Optional(level))
                    }
                }

                Button(L("Clear filters")) {
                    filter = EventFilter()
                }
            }
            .scrollContentBackground(.hidden)
            .background(Afterglow.background)
            .navigationTitle(L("Sport & level"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Done")) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
