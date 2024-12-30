import SwiftUI

struct RequestEditor: View {
    @Binding var request: APIRequest
    let onSave: (APIRequest) -> Void
    
    @State private var name: String
    @State private var url: String
    @State private var method: APIRequest.HTTPMethod
    @State private var requestBody: String
    @State private var contentType: APIRequest.ContentType
    @State private var headers: [String: String]
    @State private var newHeaderKey = ""
    @State private var newHeaderValue = ""
    
    // 新增状态
    @State private var timeout: Double
    @State private var maxRetries: Int
    @State private var followRedirects: Bool
    @State private var queryParameters: [String: String]
    @State private var newQueryKey = ""
    @State private var newQueryValue = ""
    @State private var selectedAuthType: AuthType?
    @State private var username = ""
    @State private var password = ""
    @State private var token = ""
    @State private var apiKeyName = ""
    @State private var apiKeyValue = ""
    @State private var apiKeyLocation: APIRequest.Authentication.APIKeyLocation = .header
    
    enum AuthType: String, CaseIterable {
        case none = "None"
        case basic = "Basic Auth"
        case bearer = "Bearer Token"
        case apiKey = "API Key"
    }
    
    init(request: Binding<APIRequest>, onSave: @escaping (APIRequest) -> Void) {
        self._request = request
        self.onSave = onSave
        
        _name = State(initialValue: request.wrappedValue.name)
        _url = State(initialValue: request.wrappedValue.url)
        _method = State(initialValue: request.wrappedValue.method)
        _requestBody = State(initialValue: request.wrappedValue.body ?? "")
        _contentType = State(initialValue: request.wrappedValue.contentType)
        _headers = State(initialValue: request.wrappedValue.headers)
        
        // 初始化新增状态
        _timeout = State(initialValue: request.wrappedValue.timeout)
        _maxRetries = State(initialValue: request.wrappedValue.maxRetries)
        _followRedirects = State(initialValue: request.wrappedValue.followRedirects)
        _queryParameters = State(initialValue: request.wrappedValue.queryParameters)
        
        // 初始化认证状态
        switch request.wrappedValue.authentication {
        case .basic(let u, let p):
            _selectedAuthType = State(initialValue: .basic)
            _username = State(initialValue: u)
            _password = State(initialValue: p)
        case .bearer(let t):
            _selectedAuthType = State(initialValue: .bearer)
            _token = State(initialValue: t)
        case .apiKey(let k, let v, let l):
            _selectedAuthType = State(initialValue: .apiKey)
            _apiKeyName = State(initialValue: k)
            _apiKeyValue = State(initialValue: v)
            _apiKeyLocation = State(initialValue: l)
        case .none:
            _selectedAuthType = State(initialValue: .none)
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            TabView {
                basicConfigView
                    .tabItem {
                        Label("Basic", systemImage: "doc.text")
                    }
                
                advancedConfigView
                    .tabItem {
                        Label("高级", systemImage: "gear")
                    }
                
                authenticationView
                    .tabItem {
                        Label("Auth", systemImage: "lock")
                    }
            }
            .padding()
            
            // Save Button
            Button(action: saveRequest) {
                Text("Save Request")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(name.isEmpty || url.isEmpty)
            .padding(.horizontal)
        }
    }
    
    var basicConfigView: some View {
        VStack(spacing: 16) {
            // 基本信息
            HStack {
                TextField("Request Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                
                Picker("Method", selection: $method) {
                    ForEach(APIRequest.HTTPMethod.allCases, id: \.self) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .frame(width: 100)
            }
            
            TextField("URL", text: $url)
                .textFieldStyle(.roundedBorder)
            
            // Headers
            GroupBox("Headers") {
                VStack(spacing: 8) {
                    ForEach(Array(headers.keys.sorted()), id: \.self) { key in
                        HStack {
                            TextField("Key", text: .constant(key))
                                .textFieldStyle(.roundedBorder)
                            TextField("Value", text: Binding(
                                get: { headers[key] ?? "" },
                                set: { headers[key] = $0 }
                            ))
                                .textFieldStyle(.roundedBorder)
                            Button(action: { headers.removeValue(forKey: key) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("New Header Key", text: $newHeaderKey)
                            .textFieldStyle(.roundedBorder)
                        TextField("Value", text: $newHeaderValue)
                            .textFieldStyle(.roundedBorder)
                        Button(action: addHeader) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                        .disabled(newHeaderKey.isEmpty)
                    }
                }
            }
            
            // Request Body
            GroupBox {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Content Type", selection: $contentType) {
                        ForEach(APIRequest.ContentType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    TextEditor(text: $requestBody)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 200)
                }
            }
        }
    }
    
    var advancedConfigView: some View {
        VStack(spacing: 16) {
            // Timeout
            HStack {
                Text("Timeout (seconds)")
                Slider(value: $timeout, in: 5...120, step: 5)
                Text("\(Int(timeout))")
                    .monospacedDigit()
            }
            
            // Max Retries
            Stepper("Max Retries: \(maxRetries)", value: $maxRetries, in: 0...5)
            
            // Follow Redirects
            Toggle("Follow Redirects", isOn: $followRedirects)
            
            // Query Parameters
            GroupBox("Query Parameters") {
                VStack(spacing: 8) {
                    ForEach(Array(queryParameters.keys.sorted()), id: \.self) { key in
                        HStack {
                            TextField("Key", text: .constant(key))
                                .textFieldStyle(.roundedBorder)
                            TextField("Value", text: Binding(
                                get: { queryParameters[key] ?? "" },
                                set: { queryParameters[key] = $0 }
                            ))
                                .textFieldStyle(.roundedBorder)
                            Button(action: { queryParameters.removeValue(forKey: key) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("New Parameter Key", text: $newQueryKey)
                            .textFieldStyle(.roundedBorder)
                        TextField("Value", text: $newQueryValue)
                            .textFieldStyle(.roundedBorder)
                        Button(action: addQueryParameter) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                        }
                        .disabled(newQueryKey.isEmpty)
                    }
                }
            }
        }
    }
    
    var authenticationView: some View {
        VStack(spacing: 16) {
            Picker("Authentication Type", selection: $selectedAuthType) {
                Text("None").tag(Optional<AuthType>.none)
                ForEach(AuthType.allCases.filter { $0 != .none }, id: \.self) { type in
                    Text(type.rawValue).tag(Optional<AuthType>.some(type))
                }
            }
            
            switch selectedAuthType {
            case .some(.basic):
                VStack(spacing: 8) {
                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                
            case .some(.bearer):
                TextField("Bearer Token", text: $token)
                    .textFieldStyle(.roundedBorder)
                
            case .some(.apiKey):
                VStack(spacing: 8) {
                    TextField("Key Name", text: $apiKeyName)
                        .textFieldStyle(.roundedBorder)
                    TextField("Key Value", text: $apiKeyValue)
                        .textFieldStyle(.roundedBorder)
                    Picker("Location", selection: $apiKeyLocation) {
                        Text("Header").tag(APIRequest.Authentication.APIKeyLocation.header)
                        Text("Query").tag(APIRequest.Authentication.APIKeyLocation.query)
                    }
                }
                
            case .some(.none), .none:
                Text("No authentication")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func addHeader() {
        if !newHeaderKey.isEmpty {
            headers[newHeaderKey] = newHeaderValue
            newHeaderKey = ""
            newHeaderValue = ""
        }
    }
    
    private func addQueryParameter() {
        if !newQueryKey.isEmpty {
            queryParameters[newQueryKey] = newQueryValue
            newQueryKey = ""
            newQueryValue = ""
        }
    }
    
    private func saveRequest() {
        var updatedRequest = request
        updatedRequest.name = name
        updatedRequest.url = url
        updatedRequest.method = method
        updatedRequest.headers = headers
        updatedRequest.body = requestBody.isEmpty ? nil : requestBody
        updatedRequest.contentType = contentType
        updatedRequest.timeout = timeout
        updatedRequest.maxRetries = maxRetries
        updatedRequest.followRedirects = followRedirects
        updatedRequest.queryParameters = queryParameters
        
        // 设置认证信息
        switch selectedAuthType {
        case .some(.basic):
            updatedRequest.authentication = .basic(username: username, password: password)
        case .some(.bearer):
            updatedRequest.authentication = .bearer(token: token)
        case .some(.apiKey):
            updatedRequest.authentication = .apiKey(key: apiKeyName, value: apiKeyValue, location: apiKeyLocation)
        case .some(.none), .none:
            updatedRequest.authentication = nil
        }
        
        onSave(updatedRequest)
    }
}

#Preview {
    AppPreview()
        .frame(width: 1200)
        .frame(height: 800)
}
