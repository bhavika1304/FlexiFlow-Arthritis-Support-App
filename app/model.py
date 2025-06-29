import numpy as np
import pickle
import os

class LinUCB:
    def __init__(self, alpha=1.0, num_actions=30, context_dim=15):
        """
        LinUCB: Contextual Bandit Algorithm
        :param alpha: Exploration parameter
        :param num_actions: Number of possible actions (exercises)
        :param context_dim: Dimension of context vector
        """
        self.alpha = alpha
        self.num_actions = num_actions
        self.context_dim = context_dim

        # One A and b matrix per action
        self.A = [np.identity(context_dim) for _ in range(num_actions)]
        self.b = [np.zeros((context_dim, 1)) for _ in range(num_actions)]

    def recommend(self, context_vector, top_k=5):
        """
        Recommend top-k actions given context
        :param context_vector: (context_dim x 1) numpy array
        :param top_k: how many to recommend
        :return: list of indices (actions)
        """
        p = []
        for a in range(self.num_actions):
            A_inv = np.linalg.inv(self.A[a])
            theta = A_inv @ self.b[a]
            p_ta = (theta.T @ context_vector) + self.alpha * np.sqrt(context_vector.T @ A_inv @ context_vector)
            p.append(p_ta.item())

        return np.argsort(p)[-top_k:][::-1].tolist()

    def update(self, context_vector, action, reward):
        """
        Update model with user feedback
        :param context_vector: numpy array (context_dim x 1)
        :param action: int, index of selected exercise
        :param reward: float, feedback score (e.g. 1.0 or 0.0)
        """
        context_vector = context_vector.reshape(-1, 1)
        self.A[action] += context_vector @ context_vector.T
        self.b[action] += reward * context_vector

# ---------------------- ✅ Persistence Functions ---------------------- #

MODEL_PATH = "saved_models/linucb_model.pkl"

def save_model(model):
    os.makedirs("model_store", exist_ok=True)
    with open(MODEL_PATH, "wb") as f:
        pickle.dump(model, f)

def load_model():
    if os.path.exists(MODEL_PATH):
        with open(MODEL_PATH, "rb") as f:
            return pickle.load(f)
    return None
