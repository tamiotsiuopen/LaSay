//
//  TechTermsDictionary.swift
//  VoiceScribe
//
//  Created by Claude on 2026/2/15.
//

import Foundation

struct TechTermsDictionary {
    // 常見的錯誤拼寫 → 正確拼寫
    // 只處理大小寫修正，不改語意
    static let corrections: [String: String] = [
        // Languages
        "javascript": "JavaScript",
        "typescript": "TypeScript",
        "python": "Python",
        "golang": "Golang",
        "swift": "Swift",  // 注意：只在 code context 修正
        "kotlin": "Kotlin",
        "rust": "Rust",

        // Frameworks & Libraries
        "react": "React",
        "reactjs": "React.js",
        "nextjs": "Next.js",
        "next.js": "Next.js",
        "vuejs": "Vue.js",
        "vue.js": "Vue.js",
        "angular": "Angular",
        "fastapi": "FastAPI",
        "django": "Django",
        "flask": "Flask",
        "express": "Express",
        "spring boot": "Spring Boot",
        "springboot": "Spring Boot",
        "tailwind": "Tailwind",
        "tailwind css": "Tailwind CSS",
        "swiftui": "SwiftUI",

        // Tools & Platforms
        "docker": "Docker",
        "kubernetes": "Kubernetes",
        "k8s": "K8s",
        "github": "GitHub",
        "gitlab": "GitLab",
        "git": "Git",
        "npm": "npm",
        "yarn": "yarn",
        "webpack": "webpack",
        "vite": "Vite",
        "redis": "Redis",
        "postgres": "PostgreSQL",
        "postgresql": "PostgreSQL",
        "mysql": "MySQL",
        "mongodb": "MongoDB",
        "mongo": "MongoDB",
        "sqlite": "SQLite",
        "aws": "AWS",
        "gcp": "GCP",
        "azure": "Azure",
        "terraform": "Terraform",
        "jenkins": "Jenkins",
        "nginx": "Nginx",
        "apache": "Apache",
        "linux": "Linux",
        "macos": "macOS",
        "ios": "iOS",
        "android": "Android",
        "xcode": "Xcode",
        "vs code": "VS Code",
        "vscode": "VS Code",
        "visual studio code": "VS Code",
        "intellij": "IntelliJ",
        "neovim": "Neovim",
        "vim": "Vim",

        // AI/ML
        "openai": "OpenAI",
        "chatgpt": "ChatGPT",
        "gpt": "GPT",
        "claude": "Claude",
        "langchain": "LangChain",
        "pytorch": "PyTorch",
        "tensorflow": "TensorFlow",
        "hugging face": "Hugging Face",
        "huggingface": "Hugging Face",
        "llm": "LLM",
        "rag": "RAG",
        "mlops": "MLOps",

        // Concepts & Acronyms
        "api": "API",
        "rest": "REST",
        "restful": "RESTful",
        "graphql": "GraphQL",
        "grpc": "gRPC",
        "json": "JSON",
        "yaml": "YAML",
        "html": "HTML",
        "css": "CSS",
        "sql": "SQL",
        "nosql": "NoSQL",
        "ci cd": "CI/CD",
        "cicd": "CI/CD",
        "devops": "DevOps",
        "saas": "SaaS",
        "oauth": "OAuth",
        "jwt": "JWT",
        "sdk": "SDK",
        "cli": "CLI",
        "crud": "CRUD",
        "orm": "ORM",
        "mvc": "MVC",
        "mvvm": "MVVM",
    ]

    /// 對文字套用術語修正（word boundary aware）
    static func apply(to text: String) -> String {
        var result = text
        for (wrong, correct) in corrections {
            // 使用 word boundary regex 避免部分匹配
            // 例如不要把 "expression" 裡的 "express" 改掉
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: wrong))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(result.startIndex..., in: result),
                    withTemplate: correct
                )
            }
        }
        return result
    }
}
