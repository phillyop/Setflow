import SwiftUI

struct LibraryPickerView: View {
    let onSelect: (PresetExercise) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var searchText    = ""
    @State private var selectedCategory = "All"

    private let allCategories = ["All"] + ExerciseLibrary.categories

    private var filtered: [PresetExercise] {
        let base = selectedCategory == "All"
            ? ExerciseLibrary.presets
            : ExerciseLibrary.presets(for: selectedCategory)
        return searchText.isEmpty ? base : ExerciseLibrary.search(searchText)
    }

    private var grouped: [(category: String, exercises: [PresetExercise])] {
        if selectedCategory != "All" || !searchText.isEmpty {
            return [(category: selectedCategory == "All" ? "Results" : selectedCategory, exercises: filtered)]
        }
        return ExerciseLibrary.categories.compactMap { cat in
            let exs = ExerciseLibrary.presets(for: cat)
            return exs.isEmpty ? nil : (category: cat, exercises: exs)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.setflowBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Category chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(allCategories, id: \.self) { cat in
                                Button {
                                    selectedCategory = cat
                                    Haptics.selection()
                                } label: {
                                    Text(cat)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(selectedCategory == cat ? .white : .primary.opacity(0.5))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == cat ? Color.blue : Color.primary.opacity(0.07))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }

                    Divider().background(Color.primary.opacity(0.08))

                    // Exercise list
                    List {
                        ForEach(grouped, id: \.category) { group in
                            Section {
                                ForEach(group.exercises) { preset in
                                    Button {
                                        onSelect(preset)
                                        dismiss()
                                    } label: {
                                        presetRow(preset)
                                    }
                                    .buttonStyle(.plain)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .padding(.vertical, 2)
                                }
                            } header: {
                                if grouped.count > 1 {
                                    Text(group.category)
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.primary.opacity(0.4))
                                        .textCase(nil)
                                        .tracking(0.5)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Exercise Library")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.primary.opacity(0.7))
                }
            }
        }
    }

    private func presetRow(_ preset: PresetExercise) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(preset.tracking == .weighted ? Color.blue.opacity(0.15) : Color.green.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: preset.tracking == .weighted ? "dumbbell.fill" : "figure.walk")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(preset.tracking == .weighted ? .blue : .green)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(preset.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    Text("\(preset.sets)×\(preset.reps)")
                        .font(.caption)
                        .foregroundColor(.primary.opacity(0.5))

                    if preset.defaultWeight > 0 {
                        Text("· \(Int(preset.defaultWeight))kg")
                            .font(.caption)
                            .foregroundColor(.blue.opacity(0.7))
                    }

                    Text("· \(preset.restSeconds)s rest")
                        .font(.caption)
                        .foregroundColor(.primary.opacity(0.35))
                }
            }

            Spacer()

            Image(systemName: "plus.circle")
                .font(.title3)
                .foregroundColor(.blue.opacity(0.6))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }
}
