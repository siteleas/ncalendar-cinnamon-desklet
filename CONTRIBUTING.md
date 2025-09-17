# Contributing to NextCloud Calendar Desklet

We're looking for experienced Cinnamon desklet developers to help improve and enhance this project. If you have experience with:
- Cinnamon desktop development
- GTK/St widget development
- JavaScript/GJS programming
- NextCloud/CalDAV integration

We'd love your help making this desklet better!

## Version Control and Releases

### Semantic Versioning (0.x.yyy)
This project uses semantic versioning for alpha/development releases. Version numbers can only be incremented by repository owners and administrators.

- Format: `0.x.yyy`
  - First number (0): Alpha status, controlled by repo owners
  - Second number (x): Feature set revision, controlled by repo owners
  - Third number (yyy): Build number, controlled by repo owners

Version progression is strictly managed:
- Only repository owners can create version tags
- Only repository owners can increment version numbers
- Version numbers are updated through protected branch merges

### Contributing Code

1. **Fork the Repository**
   - Create your own fork of the project
   - Create a feature branch for your work

2. **Development Guidelines**
   - Follow existing code style and patterns
   - Maintain compatibility with supported Cinnamon versions
   - Include appropriate error handling
   - Add logging for debugging
   - Test across different monitor configurations

3. **Pull Requests**
   - Open a PR against the `develop` branch
   - Provide clear description of changes
   - Include testing steps and results
   - Link to any related issues

4. **Code Review**
   - All PRs require review by maintainers
   - Changes may be requested
   - Documentation must be updated
   - Tests must pass

### Documentation

When contributing, please update relevant documentation:
- Code comments for new functions
- README.md for user-facing changes
- Configuration examples if needed

### Testing

Test your changes across:
- Different Cinnamon versions
- Multiple monitor setups
- Various NextCloud configurations

## Getting Help

- Open an issue for questions
- Join our development discussions
- Check existing issues and PRs

Thank you for considering contributing to the NextCloud Calendar Desklet project!
