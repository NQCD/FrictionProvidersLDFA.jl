"""
This uses a SciKit ML models to attach friction coefficients to existing models by fitting the data
provided by Gerrits et al. in PHYSICAL REVIEW B 102, 155130 (2020).
"""

struct SciKitDensity{D,L,A,U}
    "Descriptors used for scikit models"
    descriptors::D
    "Sci-Kit ML model"
    ml_model::L
    "Atoms"
    atoms::A
    "Units"
    density_unit::U
end

function SciKitDensity(descriptors, ml_model, atoms; density_unit=u"Å^-3")
    SciKitDensity(descriptors, ml_model, atoms, density_unit)
end

function set_coordinates!(model::SciKitDensity, R)
    model.atoms.set_positions(ustrip.(auconvert.(u"Å", R')))
end

function density!(model::SciKitDensity, rho::AbstractVector, R::AbstractMatrix, friction_atoms::AbstractVector)
    for i in friction_atoms
        set_coordinates!(model, R)
        density_atoms = model.atoms.copy()
        friction_atoms_srtd = sort(friction_atoms, rev=true)
        for j=1:length(friction_atoms_srtd)
            density_atoms.pop(i=friction_atoms_srtd[j]-1)
        end
        density_atoms.append(model.atoms[i])
        r_desc = model.descriptors.create(density_atoms, positions=[length(density_atoms)-1], n_jobs=1) #n_threads)
        rho[i] = austrip(model.ml_model.predict(r_desc)[end] * model.density_unit)
    end
end

