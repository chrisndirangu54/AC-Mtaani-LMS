"""Safe placeholder for the lab execution service.

This program intentionally does not fetch or execute user code.
Deploy a sandbox orchestrator and worker identity before enabling labs.
"""
if __name__ == "__main__":
    print("Lab worker deployment requires isolated execution runtime and workload identity.")
