import SwiftUI

struct EventFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var filter: EventFilter

    var body: some View {
        NavigationStack {
            Form {
                Picker("Sport", selection: $filter.sport) {
                    Text("All sports").tag(nil as Sport?)

                    ForEach(Sport.allCases, id: \.self) { sport in
                        Text(sport.rawValue).tag(Optional(sport))
                    }
                }

                Picker("Level", selection: $filter.level) {
                    Text("All levels").tag(nil as EventLevel?)

                    ForEach(EventLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(Optional(level))
                    }
                }

                Button("Clear filters") {
                    filter = EventFilter()
                }
            }
            .scrollContentBackground(.hidden)
            .background(Afterglow.background)
            .navigationTitle("Sport & level")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
