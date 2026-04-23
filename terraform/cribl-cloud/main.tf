terraform {
  required_providers {
    criblio = {
      source  = "criblio/criblio"
      version = "1.23.20"
    }
  }
}

provider "criblio" {
  # Credentials will be read from environment variables
}

