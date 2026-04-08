use std::path::PathBuf;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum PdError {
    #[error("bookmark '{0}' not found")]
    NotFound(String),

    #[error("path does not exist: {0}")]
    PathNotFound(PathBuf),

    #[error("invalid bookmark name '{name}': {reason}")]
    InvalidName { name: String, reason: String },

    #[error("could not determine home directory")]
    NoHomeDir,

    #[error("{0}")]
    Other(String),

    #[error("{0}")]
    Io(#[from] std::io::Error),
}

impl PdError {
    pub fn exit_code(&self) -> i32 {
        match self {
            PdError::NotFound(_) => 2,
            PdError::PathNotFound(_) => 3,
            PdError::Io(_) | PdError::NoHomeDir => 4,
            PdError::InvalidName { .. } => 5,
            PdError::Other(_) => 1,
        }
    }
}
