class ResourceAlreadyExistsError(Exception):
    def __init__(self, resource_type: str, name: str) -> None:
        self.resource_type = resource_type
        self.name = name
        super().__init__(f"{resource_type} '{name}' already exists")


class InsufficientPermissionsError(Exception):
    def __init__(self, action: str) -> None:
        self.action = action
        super().__init__(f"Insufficient permissions to perform: {action}")
