//
//  TechTermsDictionary.swift
//  VoiceScribe
//
//  Created by Tamio Tsiu on 2026/2/15.
//
//  Offline-only tech term corrections for SenseVoice mode.
//  When AI Polish is enabled, GPT handles this contextually — skip this dictionary.
//
//  Rules for adding entries:
//  1. Only add terms that are UNAMBIGUOUS (no common English words like "swift", "rust", "dart")
//  2. The wrong form must be clearly wrong (e.g., "javascript" is always JavaScript)
//  3. Prefer multi-word or compound terms that won't match normal speech

import Foundation

struct TechTermsDictionary {

    // MARK: - English corrections (case-insensitive, word boundary)
    // Only unambiguous terms — no common English words
    static let corrections: [String: String] = [
        // Languages (only unambiguous ones)
        "javascript": "JavaScript",
        "typescript": "TypeScript",
        "python": "Python",
        "golang": "Golang",
        "kotlin": "Kotlin",
        "c sharp": "C#",
        "c plus plus": "C++",
        "objective c": "Objective-C",
        "objective-c": "Objective-C",
        "haskell": "Haskell",
        "clojure": "Clojure",
        "elixir": "Elixir",
        "php": "PHP",
        "scala": "Scala",

        // Frameworks (unambiguous compound names)
        "reactjs": "React.js",
        "react native": "React Native",
        "nextjs": "Next.js",
        "next.js": "Next.js",
        "vuejs": "Vue.js",
        "vue.js": "Vue.js",
        "nuxtjs": "Nuxt.js",
        "sveltekit": "SvelteKit",
        "tailwind css": "Tailwind CSS",
        "tailwindcss": "Tailwind CSS",
        "swiftui": "SwiftUI",
        "uikit": "UIKit",
        "jetpack compose": "Jetpack Compose",
        "flutter": "Flutter",
        "fastapi": "FastAPI",
        "expressjs": "Express.js",
        "nestjs": "NestJS",
        "spring boot": "Spring Boot",
        "springboot": "Spring Boot",
        "dotnet": ".NET",
        "asp.net": "ASP.NET",
        "aspnet": "ASP.NET",
        "ruby on rails": "Ruby on Rails",

        // Data Science / ML / AI
        "numpy": "NumPy",
        "scipy": "SciPy",
        "scikit learn": "scikit-learn",
        "sklearn": "scikit-learn",
        "matplotlib": "Matplotlib",
        "xgboost": "XGBoost",
        "lightgbm": "LightGBM",
        "catboost": "CatBoost",
        "pytorch": "PyTorch",
        "tensorflow": "TensorFlow",
        "hugging face": "Hugging Face",
        "huggingface": "Hugging Face",
        "chatgpt": "ChatGPT",
        "openai": "OpenAI",
        "langchain": "LangChain",
        "llamaindex": "LlamaIndex",
        "llama index": "LlamaIndex",
        "jupyterlab": "JupyterLab",
        "jupyter notebook": "Jupyter Notebook",
        "streamlit": "Streamlit",
        "stable diffusion": "Stable Diffusion",
        "midjourney": "Midjourney",
        "anthropic": "Anthropic",
        "fine tuning": "fine-tuning",
        "finetuning": "fine-tuning",

        // Data Engineering
        "pyspark": "PySpark",
        "airflow": "Airflow",
        "bigquery": "BigQuery",
        "databricks": "Databricks",
        "delta lake": "Delta Lake",
        "snowflake": "Snowflake",
        "redshift": "Redshift",
        "power bi": "Power BI",

        // Databases
        "postgresql": "PostgreSQL",
        "postgres": "PostgreSQL",
        "mysql": "MySQL",
        "mariadb": "MariaDB",
        "mongodb": "MongoDB",
        "sqlite": "SQLite",
        "dynamodb": "DynamoDB",
        "elasticsearch": "Elasticsearch",
        "opensearch": "OpenSearch",
        "supabase": "Supabase",
        "firebase": "Firebase",
        "cockroachdb": "CockroachDB",
        "chromadb": "ChromaDB",

        // DevOps / Cloud
        "kubernetes": "Kubernetes",
        "docker": "Docker",
        "terraform": "Terraform",
        "cloudflare": "Cloudflare",
        "digitalocean": "DigitalOcean",
        "github actions": "GitHub Actions",
        "gitlab ci": "GitLab CI",
        "circleci": "CircleCI",
        "argocd": "ArgoCD",
        "prometheus": "Prometheus",
        "grafana": "Grafana",
        "datadog": "Datadog",
        "cloudformation": "CloudFormation",

        // Tools
        "github": "GitHub",
        "gitlab": "GitLab",
        "bitbucket": "Bitbucket",
        "webpack": "webpack",
        "esbuild": "esbuild",
        "turbopack": "Turbopack",
        "turborepo": "Turborepo",
        "vs code": "VS Code",
        "vscode": "VS Code",
        "visual studio code": "VS Code",
        "intellij": "IntelliJ",
        "pycharm": "PyCharm",
        "webstorm": "WebStorm",
        "neovim": "Neovim",
        "claude code": "Claude Code",

        // Acronyms (always uppercase, unambiguous)
        "graphql": "GraphQL",
        "grpc": "gRPC",
        "restful": "RESTful",
        "websocket": "WebSocket",
        "ci cd": "CI/CD",
        "cicd": "CI/CD",
        "devops": "DevOps",
        "devsecops": "DevSecOps",
        "oauth": "OAuth",
        "a b test": "A/B Test",
        "ab test": "A/B Test",

        // OS (unambiguous)
        "macos": "macOS",
        "ios": "iOS",
        "ubuntu": "Ubuntu",
        "centos": "CentOS",
        "linux": "Linux",
    ]

    // MARK: - Chinese corrections (direct match, no word boundary)
    // Only entries where input ≠ output
    static let chineseCorrections: [String: String] = [
        // Whisper/SenseVoice 常見中文音譯錯誤
        "賈法": "Java",
        "賈瓦": "Java",
        "派森": "Python",
        "拍森": "Python",

        // 中文→英文術語（更精確的表達）
        "程式碼審查": "Code Review",
        "代碼審查": "Code Review",
        "P值": "p-value",
        "p值": "p-value",
        "皮值": "p-value",
        "型一錯誤": "Type I Error",
        "型二錯誤": "Type II Error",
        "第一類型錯誤": "Type I Error",
        "第二類型錯誤": "Type II Error",
        "自助法": "Bootstrap",
        "最大後驗估計": "MAP 估計",
        "丟棄法": "Dropout",
        "獨熱編碼": "One-Hot Encoding",
        "標籤編碼": "Label Encoding",
        "提示工程": "Prompt Engineering",
        "生成式AI": "生成式 AI",
        "生成式ai": "生成式 AI",

        // 統一用詞（台灣慣用）
        "緩存": "快取",
        "正態分佈": "常態分佈",
        "泊松分佈": "卜瓦松分佈",
        "貝塔分佈": "Beta 分佈",
        "伽瑪分佈": "Gamma 分佈",
        "貝葉斯": "貝氏",
        "羅吉斯迴歸": "邏輯迴歸",
        "支撐向量機": "支持向量機",
        "偏差變異數權衡": "偏差-變異數權衡",
    ]

    // MARK: - Pre-compiled patterns

    private static let compiledPatterns: [(NSRegularExpression, String)] = {
        corrections.compactMap { (wrong, correct) in
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: wrong))\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                return nil
            }
            return (regex, correct)
        }
    }()

    private static let compiledChinesePatterns: [(NSRegularExpression, String)] = {
        chineseCorrections.compactMap { (wrong, correct) in
            let pattern = NSRegularExpression.escapedPattern(for: wrong)
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                return nil
            }
            return (regex, correct)
        }
    }()

    // MARK: - Apply

    /// Apply tech term corrections. Only used in offline mode (AI Polish handles this when enabled).
    static func apply(to text: String) -> String {
        var result = text
        for (regex, correct) in compiledPatterns {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: correct
            )
        }
        for (regex, correct) in compiledChinesePatterns {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: correct
            )
        }
        return result
    }
}
