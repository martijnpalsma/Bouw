import SwiftUI

struct DossierView: View {
    @EnvironmentObject var data: InspectionData
    @EnvironmentObject var appLock: AppLockService
    @State private var showingBusinessTypePicker = false
    @State private var buildingPendingDelete: Building?
    @State private var showingSecurity = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Bedrijfsgegevens")
                            .font(.headline)

                        TextField("Bedrijfsnaam", text: $data.companyName)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: data.companyName) { _, _ in data.scheduleAutosave() }

                        TextField("Adres", text: $data.address)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: data.address) { _, _ in data.scheduleAutosave() }

                        TextField("Contactpersoon", text: $data.contactPerson)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: data.contactPerson) { _, _ in data.scheduleAutosave() }

                        DatePicker("Inspectiedatum", selection: $data.inspectionDate, displayedComponents: .date)
                            .onChange(of: data.inspectionDate) { _, _ in data.scheduleAutosave() }

                        Picker("Status", selection: $data.lifecycleStatus) {
                            ForEach(InspectionLifecycleStatus.allCases, id: \.self) { status in
                                Text(status.rawValue).tag(status)
                            }
                        }
                        .onChange(of: data.lifecycleStatus) { _, _ in data.scheduleAutosave() }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Soort bedrijf / bedrijfsactiviteit")
                            .font(.headline)

                        Button(action: { showingBusinessTypePicker = true }) {
                            HStack {
                                Text(data.selectedBusinessTypes.isEmpty
                                     ? "Selecteer bedrijfstype(n)"
                                     : data.selectedBusinessTypes.joined(separator: ", "))
                                    .foregroundStyle(data.selectedBusinessTypes.isEmpty ? .secondary : .primary)
                                    .lineLimit(2)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        if !data.selectedBusinessTypes.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(data.selectedBusinessTypes, id: \.self) { type in
                                    HStack(spacing: 4) {
                                        Text(type).font(.caption)
                                        Button {
                                            data.selectedBusinessTypes.removeAll { $0 == type }
                                            data.scheduleAutosave()
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Te inspecteren onderdelen")
                            .font(.headline)

                        Toggle("Gebouwen", isOn: $data.inspectBuildings)
                            .onChange(of: data.inspectBuildings) { _, _ in data.scheduleAutosave() }
                        Toggle("Inventaris", isOn: $data.inspectInventory)
                            .onChange(of: data.inspectInventory) { _, _ in data.scheduleAutosave() }
                        Toggle("Goederen", isOn: $data.inspectGoods)
                            .onChange(of: data.inspectGoods) { _, _ in data.scheduleAutosave() }
                        Toggle("Bedrijfsschade", isOn: $data.inspectDamage)
                            .onChange(of: data.inspectDamage) { _, _ in data.scheduleAutosave() }
                    }

                    if data.inspectBuildings {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Gebouwen")
                                    .font(.headline)
                                Spacer()
                                Button {
                                    _ = data.addBuilding()
                                } label: {
                                    Label("Gebouw toevoegen", systemImage: "plus.circle.fill")
                                }
                            }

                            if data.buildings.isEmpty {
                                Text("Nog geen gebouwen toegevoegd")
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ForEach($data.buildings) { $building in
                                    NavigationLink {
                                        BuildingDetailView(building: $building)
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(building.displayCode)
                                                    .font(.system(.body, design: .monospaced))
                                                    .fontWeight(.semibold)
                                                Text(building.name)
                                                    .font(.subheadline)
                                                if !building.function.isEmpty {
                                                    Text(building.function)
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            buildingPendingDelete = building
                                        } label: {
                                            Label("Verwijderen", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Dossier")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSecurity = true
                    } label: {
                        Image(systemName: "lock.shield")
                    }
                    .accessibilityLabel("Privacy en beveiliging")
                }
            }
            .sheet(isPresented: $showingBusinessTypePicker) {
                BusinessTypePickerView(selectedTypes: $data.selectedBusinessTypes)
                    .onDisappear { data.scheduleAutosave() }
            }
            .sheet(isPresented: $showingSecurity) {
                SecuritySettingsView()
                    .environmentObject(data)
                    .environmentObject(appLock)
            }
            .alert(
                "Gebouw verwijderen?",
                isPresented: Binding(
                    get: { buildingPendingDelete != nil },
                    set: { if !$0 { buildingPendingDelete = nil } }
                ),
                presenting: buildingPendingDelete
            ) { building in
                Button("Annuleer", role: .cancel) { buildingPendingDelete = nil }
                Button("Verwijder \(building.displayCode)", role: .destructive) {
                    data.removeBuilding(building)
                    buildingPendingDelete = nil
                }
            } message: { building in
                Text("Weet u zeker dat u \(building.displayCode) wilt verwijderen? Gekoppelde antwoorden en foto's worden verwijderd.")
            }
        }
    }
}

struct BusinessTypePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTypes: [String]
    @State private var searchText = ""
    @State private var customType = ""
    @State private var showingCustomInput = false

    var filteredTypes: [String] {
        if searchText.isEmpty { return QuestionDatabase.businessTypes }
        return QuestionDatabase.businessTypes.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBar(text: $searchText).padding()
                List {
                    ForEach(filteredTypes, id: \.self) { type in
                        Button {
                            if selectedTypes.contains(type) {
                                selectedTypes.removeAll { $0 == type }
                            } else {
                                selectedTypes.append(type)
                            }
                        } label: {
                            HStack {
                                Text(type).foregroundStyle(.primary)
                                Spacer()
                                if selectedTypes.contains(type) {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.blue)
                                }
                            }
                        }
                    }

                    Button { showingCustomInput = true } label: {
                        Label("Anders, namelijk...", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("Selecteer bedrijfstype(n)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Klaar") { dismiss() }
                }
            }
            .alert("Aangepast bedrijfstype", isPresented: $showingCustomInput) {
                TextField("Type bedrijf", text: $customType)
                Button("Annuleer", role: .cancel) {}
                Button("Toevoegen") {
                    if !customType.isEmpty {
                        selectedTypes.append(customType)
                        customType = ""
                    }
                }
            }
        }
    }
}

struct BuildingDetailView: View {
    @EnvironmentObject var data: InspectionData
    @Binding var building: Building
    @State private var showingCategoryPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Gebouwcode").font(.headline)
                    Text(building.displayCode)
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.bold)
                    Text("Interne ID: \(building.id.uuidString.prefix(8))…")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Basisgegevens").font(.headline)
                    TextField("Gebouwnaam", text: $building.name)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: building.name) { _, _ in data.scheduleAutosave() }
                    TextField("Omschrijving", text: $building.description)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: building.description) { _, _ in data.scheduleAutosave() }
                    TextField("Gebruik/functie", text: $building.function)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: building.function) { _, _ in data.scheduleAutosave() }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Technische gegevens").font(.headline)
                    optionalNumberField("Bouwjaar", value: $building.constructionYear)
                    optionalDoubleField("Oppervlakte (m²)", value: $building.area)
                    optionalNumberField("Aantal bouwlagen", value: $building.floors)
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Risicocategorieën").font(.headline)
                        Spacer()
                        Button { showingCategoryPicker = true } label: {
                            Image(systemName: "plus.circle.fill").foregroundStyle(.blue)
                        }
                    }

                    if building.categories.isEmpty {
                        Text("Geen specifieke categorieën toegevoegd")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    } else {
                        FlowLayout(spacing: 8) {
                            ForEach(building.categories, id: \.self) { category in
                                HStack(spacing: 4) {
                                    Text(category).font(.caption)
                                    Button {
                                        building.categories.removeAll { $0 == category }
                                        data.scheduleAutosave()
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Gebouwdetails")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCategoryPicker) {
            BusinessTypePickerView(selectedTypes: $building.categories)
                .onDisappear { data.scheduleAutosave() }
        }
    }

    @ViewBuilder
    private func optionalNumberField(_ title: String, value: Binding<Int?>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("", value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
                .textFieldStyle(.roundedBorder)
                .onChange(of: value.wrappedValue) { _, _ in data.scheduleAutosave() }
        }
    }

    @ViewBuilder
    private func optionalDoubleField(_ title: String, value: Binding<Double?>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
                .textFieldStyle(.roundedBorder)
                .onChange(of: value.wrappedValue) { _, _ in data.scheduleAutosave() }
        }
    }
}
