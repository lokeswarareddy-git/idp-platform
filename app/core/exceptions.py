class ResourceAlreadyExistsError(Exception):
    def __init__(self, resource_type: str, name: str) -> None:
        self.resource_type = resource_type
        self.name = name
        super().__init__(f"{resource_type} '{name}' already exists")
